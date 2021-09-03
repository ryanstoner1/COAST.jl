from flask import Flask, request, make_response, jsonify
from werkzeug.utils import secure_filename
import numpy as np
import json
import requests
import chaospy as chp
import os 

app = Flask(__name__)

@app.route('/test')
def hello_world():
    return 'Hello, World!'

@app.route("/get_coast_ip", methods=["GET"])
def get_coast_ip():
    response = jsonify({'ip': request.remote_addr})
    response.headers.add("Access-Control-Allow-Origin", "*")
    return response

@app.route('/getNBounds', methods=['GET','POST'])
def getNBounds():
    print("ran nbounds")
    if request.method == 'POST':
        # print("started post")
        data = request.form.get("npoints")
        data = json.loads(data)
        botBound = data["botBound"]
        topBound = data["topBound"]
        timeBound = data["timeBound"]

        nPoints = int(data["nPoints"])
        maxt = max(timeBound)
        mint = min(timeBound)
        timeShort = np.linspace(maxt,mint,nPoints)
        timeBound.reverse()
        botBound.reverse()
        topBound.reverse()
        botShort = np.interp(timeShort,timeBound,botBound)
        topShort = np.interp(timeShort,timeBound,topBound)
        response = jsonify({"time": timeShort.tolist(), "bot": botShort.tolist(), "top": topShort.tolist()})
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response
    else: 
        error_get =  "error in NBounds!"
        error_get = jsonify(error_get)
        error_get.headers.add("Access-Control-Allow-Origin", "*")
    return error_get

@app.route('/getPCE', methods=['GET','POST'])
def getPCE():
    if request.method == 'POST':

        data = request.form.get("param1")
        data = json.loads(data)
        key_list = []
        expand_list = []
        for key in data.keys():
            try:
                if data[key]["max"] and data[key]["min"]:
                    expand_list.append(chp.Uniform(float(data[key]["min"]), float(data[key]["max"])))
                    key_list.append(key)
                    print("found expansion parameter")
                else:                
                    print("Not varying parameter %s \n".format(key))
            except:
                print("skipped numberX and numberZ")

        joint_distribution = chp.J(*expand_list)
        expansion = chp.generate_expansion(5, joint_distribution)
        samples = joint_distribution.sample(int(data["numberX"]), rule="sobol")
        response = jsonify([key_list, samples.tolist()])
        response.headers.add("Access-Control-Allow-Origin", "*")
        julia_data = {
            "function_to_run": "global_sensitivity",
            "samples": samples.tolist(),
            "key_list": key_list,
            "data": data,
        }
        r = requests.post('http://0.0.0.0:8000/model',json = julia_data)
        try:
            dates = np.array(json.loads(r.text))
        except:
            print(r.text)
        
        return response 
    else:
        error_get = "Error in PCE expansion!"
    return error_get

@app.route('/getfile', methods=['GET','POST'])
def getfile():
    if request.method == 'POST':
        # for secure filenames. Read the documentation.
        file = request.files["file"]
        filename = secure_filename(file.filename) 
        # print(file)
        file_content = file.read()
        raw_file_response = parse_hefty_output(file_content)
        response = jsonify(raw_file_response)
        response.headers.add("Access-Control-Allow-Origin", "*")

        #
        return response 
    else:
        error_get = "Error!"
    return error_get

def parse_hefty_output(text_blob):
    # initialize constraints and constraint boxes
    n_extra_constraints = 0 
    min_times = np.array([])
    max_times = np.array([])
    min_temp = np.array([])
    max_temp = np.array([])
    dates = np.array([])
    tT_names = []
    hasreached_first_Tt = [False, False]

    default_envelope_line_ind = 6 
    starting_Tt = False
    is_time_Tt = True

    # open file and loop through lines
    lines = text_blob.split(b'\n')
    
    for (ind,line) in enumerate(lines):
        if ind>1:
            line_split = line.split(b'\t')

            # CONSTRAINT BOXES
            if line_split[0].isdigit():
                # get constraint box parameters
                line_arr = np.array(line_split).astype(float)
                max_times = np.append(max_times, line_arr[1])
                min_times = np.append(min_times, line_arr[2])
                max_temp = np.append(max_temp, line_arr[3])
                min_temp = np.append(min_temp, line_arr[4])
                
                # default number constraints 2
                if ind>3:
                    n_extra_constraints += 1

            # GOOD/ACCEPTABLE ENVELOPES
            else:    
                if ind == default_envelope_line_ind+n_extra_constraints:
                    good_time = np.array(line_split[3:]).astype(float)
                if ind== default_envelope_line_ind+n_extra_constraints+1:
                    good_hi = np.array(line_split[3:]).astype(float)
                if ind== default_envelope_line_ind+n_extra_constraints+2:
                    good_lo = np.array(line_split[3:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+3:
                    acc_time = np.array(line_split[3:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+4:
                    acc_hi = np.array(line_split[3:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+5:
                    acc_lo = np.array(line_split[3:]).astype(float)
            
            # see if Tt path data coming up next
            if line_split[0]==b'Time (Ma)':
                max_time = line_split[1]
            if line_split[0]==b'Temp (C)':
                max_temp = line_split[1]
            if line_split[0]==b'Fit':
                starting_Tt = True
                starting_ind = ind+1

        # INDIVIDUAL Tt PATHS
        if starting_Tt and (ind>=starting_ind):
            
            line_split = line.split(b'\t')

            # T-t path upper line contains time data, lower line temperature data
            # test for EOF that becomes empty byte string
            if is_time_Tt and (line_split[0]!=b''):
                                
                n_dates = 0
                while (b'Time (Ma)' not in line_split[n_dates]) and (n_dates<100):
                    n_dates += 1
                n_dates -= 1
                
                new_dates = np.array(line_split[1:n_dates+1]).astype(float)
                # check if empty to avoid dimension mismatch
                dates = np.vstack((dates,new_dates)) if dates.size else new_dates
                
                t_Tt = np.array(line_split[2+n_dates:]).astype(float)
                t_Tt = t_Tt[::-1]
                
                line_split[0] = line_split[0].decode()
                if 'Good' in line_split[0]:
                    name_Tt = [line_split[0],"good"]
                elif 'Acc' in line_split[0]:
                    name_Tt = [line_split[0],"acc"]
                elif 'Best' in line_split[0]:
                    name_Tt = [line_split[0],"best"]
                else:
                    print("must have good, acceptable or best!")
                tT_names.append(name_Tt)

                if not hasreached_first_Tt[0]:
                    hasreached_first_Tt[0] = True
                    t_Ma = np.empty((0,len(t_Tt)))
                    
                    acc_time_interp = np.empty((0,len(acc_time)))
                    good_time_interp = np.empty((0,len(good_time)))
                t_Ma = np.vstack((t_Ma,t_Tt))
                is_time_Tt = False 


            elif not is_time_Tt and (line_split[0]!=b''):               
                T_Tt = np.array(line_split[2+n_dates:]).astype(float)
                T_Tt = T_Tt[::-1]
                if not hasreached_first_Tt[1]:
                    hasreached_first_Tt[1] = True
                    T_celsius = np.empty((0,len(T_Tt)))

                T_celsius = np.vstack((T_celsius,T_Tt))
            
                good_time_interp_line = np.interp(good_time,t_Tt,T_Tt)
                good_time_interp = np.vstack((good_time_interp,good_time_interp_line))
                acc_time_interp_line = np.interp(acc_time,t_Tt,T_Tt)
                acc_time_interp = np.vstack((acc_time_interp,acc_time_interp_line))
                is_time_Tt = True

    hefty_data = {
        "good_time": good_time.tolist(),
        "acc_time": acc_time.tolist(),
        "good_hi": good_hi.tolist(),
        "good_lo": good_lo.tolist(),
        "acc_hi": acc_hi.tolist(),
        "acc_lo": acc_lo.tolist(),
        "good_time_interp": good_time_interp.tolist(),
        "acc_time_interp": acc_time_interp.tolist(),
        "t_Ma": t_Ma.tolist(),
        "T_celsius": T_celsius.tolist(),
        "tT_names": tT_names,
        "dates": dates.tolist(),
        "max_temp": float(max_temp),
        "max_time": float(max_time),
    }

    return hefty_data

if __name__ == '__main__':
   app.run(debug = True)
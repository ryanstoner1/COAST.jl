from app import app
import io
import base64
import datetime
import numpy as np
from dash.exceptions import PreventUpdate
import pandas as pd
import dash_table
import dash_html_components as html
import dash_core_components as dcc
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output, State
page_2_layout = html.Div([
    html.Div([   
        html.H2("Type of sensitivity analysis",style={
            'padding': "10px",
        }),         
        dcc.RadioItems(
            options=[
                {'label': ' Inverse', 'value': 'Inv'},
                {'label': ' Forward', 'value': 'For'},  
            ],
            value='Inv',
            labelStyle={
                'display': 'block', 
                "padding-left": "10px",
                'font-weight': 300,
                'font-size': '20px',
            }
        ),
        dcc.RadioItems(
            options=[
                {'label': ' Using COAST', 'value': 'COAST'},
                {'label': ' Postprocessing HeFTy', 'value': 'HEF'}
            ],
            value='COAST',
            id="collapse-radio",
            labelStyle={
                'display': 'block', 
                "padding-left": "20px",
                'font-weight': 300,
                'font-size': '20px',
            }
        ),
        dbc.DropdownMenu(
            label="Diffusion type",
            children=[
                dbc.DropdownMenuItem("U-Pb Apatite (Cherniak, 2000)", id="ap-button",href="/page-3"),
                dbc.DropdownMenuItem("U-Th/He Apatite"),
                dbc.DropdownMenuItem("U-Th/He Zircon"),
                dbc.DropdownMenuItem("U-Th/He Titanite"),
            ],
        ),
        dbc.Card(dbc.CardBody(
            dcc.Upload(
            id='upload-data',
            children=html.Div([
                'Drag and Drop or ',
                html.A('Select', style={'color': 'blue','text-decoration': 'underline','cursor': 'pointer'}),
                ' HeFTy files'
            ]),
            style={
                'transition-duration': '0s',
                'width': '100%',
                'height': '60px',
                'lineHeight': '60px',
                'borderWidth': '1px',
                'borderStyle': 'dashed',
                'borderRadius': '5px',
                'textAlign': 'center',
                'margin': '10px'
            },
            # Allow multiple files to be uploaded
            multiple=True
            )
        )),
        html.Div(id='output-data-upload'),
    ]),
]) 

@app.callback(Output('session', 'data'),
                Input('ap-button', 'n_clicks'),
                State('session', 'data'))
def on_click(n_clicks, data):
    if n_clicks is None:
        # prevent the None callbacks is important with the store component.
        # you don't want to update the store for nothing.
        raise PreventUpdate

    # Give a default data dict with 0 clicks if there's no data.
    data = data or {'D0': None, 'Ea': None}
    data['Ea'] = 250*1e3
    data['D0'] = 3.9*1e-10#data['clicks'] + 1
    return data

def parse_hefty_output(text_blob):
    # initialize constraints and constraint boxes
    n_extra_constraints = 0 
    min_times = np.array([])
    max_times = np.array([])
    min_temp = np.array([])
    max_temp = np.array([])
    date = np.array([])
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
                    good_hi = np.array(line_split[4:]).astype(float)
                if ind== default_envelope_line_ind+n_extra_constraints+2:
                    good_lo = np.array(line_split[4:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+3:
                    acc_time = np.array(line_split[3:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+4:
                    acc_hi = np.array(line_split[4:]).astype(float)
                if ind == default_envelope_line_ind+n_extra_constraints+5:
                    acc_lo = np.array(line_split[4:]).astype(float)
            
            # see if Tt path data coming up
            if line_split[0]==b'Fit':
                starting_Tt = True
                starting_ind = ind+1

        # INDIVIDUAL Tt PATHS
        if starting_Tt and (ind>=starting_ind):
            
            line_split = line.split(b'\t')
            
            # T-t path upper line contains time data, lower line temperature data
            if is_time_Tt:                
                date = np.append(date,line_split[1])
                t_Tt = np.array(line_split[4:]).astype(float)
                t_Tt = t_Tt[::-1]
                if not hasreached_first_Tt[0]:
                    hasreached_first_Tt[0] = True
                    time_Ma = np.empty((0,len(t_Tt)))
                    acc_time_interp = np.empty((0,len(acc_time)))
                    good_time_interp = np.empty((0,len(good_time)))

                time_Ma = np.vstack((time_Ma,t_Tt))
                is_time_Tt = False
                               
            else:               
                T_Tt = np.array(line_split[4:]).astype(float)
                T_Tt = T_Tt[::-1]
                if not hasreached_first_Tt[1]:
                    hasreached_first_Tt[1] = True
                    T_celsius = np.empty((0,len(T_Tt)))

                T_celsius = np.vstack((T_celsius,T_Tt))
                
                print(good_time)
                good_time_interp_line = np.interp(good_time,t_Tt,T_Tt)
                good_time_interp = np.vstack((good_time_interp,good_time_interp_line))
                acc_time_interp_line = np.interp(acc_time,t_Tt,T_Tt)
                acc_time_interp = np.vstack((acc_time_interp,acc_time_interp_line))
                is_time_Tt = True
    hefty_data = {
        "good_time_interp_line": np.copy(good_time_interp_line),
        "good_time_interp": np.copy(good_time_interp),
        "acc_time_interp_line": np.copy(acc_time_interp_line),
        "acc_time_interp": np.copy(acc_time_interp),
        "is_time_Tt": np.copy(is_time_Tt),
        "T_Tt": np.copy(T_Tt),
    }
    return hefty_data

def parse_contents(contents, filename, date):
    content_type, content_string = contents.split(',')

    text_blob = base64.b64decode(content_string)
    # try:
    if 'txt' in filename:
        success_dict = parse_hefty_output(text_blob)
    # except Exception as e:
    #     print(e)
    #     return html.Div([
    #         'There was an error processing this file.'
    #     ])

    return html.Div([
        html.H5(filename),
        html.H6(datetime.datetime.fromtimestamp(date)),

        html.Hr(),  # horizontal line

        # For debugging, display the raw contents provided by the web browser
        html.Div('Raw Content'),
        html.Pre(contents[0:200] + '...', style={
            'whiteSpace': 'pre-wrap',
            'wordBreak': 'break-all'
        }),
        dcc.Store(id='memory-output', data=success_dict),
        dbc.DropdownMenu(
            label="sensitivity analysis options",
            children=[
                dbc.DropdownMenuItem("keep original T-t paths", id="original-Tt"),
                dbc.DropdownMenuItem("add more T-t paths", id="add-Tt"),
                dbc.DropdownMenuItem("add non-HeFTy based sources of uncertainty", id="extra-Tt"),
            ],
        ),
    ])

@app.callback(Output('output-data-upload', 'children'),
              Input('upload-data', 'contents'),
              State('upload-data', 'filename'),
              State('upload-data', 'last_modified'))
def update_output(list_of_contents, list_of_names, list_of_dates):
    if list_of_contents is not None:
        children = [
            parse_contents(c, n, d) for c, n, d in
            zip(list_of_contents, list_of_names, list_of_dates)]
        return children

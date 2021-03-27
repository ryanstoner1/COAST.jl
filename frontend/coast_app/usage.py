import coast_app
import io
import dash
import base64
import requests
import datetime
import dash_auth
import dash_table
import pandas as pd
import numpy as np
from dash.dependencies import Input, Output
import dash_html_components as html
import dash_core_components as dcc

# Password for users
VALID_USERNAME_PASSWORD_PAIRS = {
    'thermo': 'Apatite3'
}
external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']

app = dash.Dash(__name__, external_stylesheets=external_stylesheets)
server = app.server
auth = dash_auth.BasicAuth(
    app,
    VALID_USERNAME_PASSWORD_PAIRS
)

app.layout = html.Div([dcc.Tabs(id='tabs-example', value='tab-1', children=[
    dcc.Tab(label='He Diffusion', children=[
        coast_app.CoastApp(
            id='input',
            value='my-value',
            label='[10,20]'
        ),
        html.Div(["Input: ",
                  dcc.Input(id='my-input', value=90, type='number')]),
        html.Button('Submit', id='submit-val', n_clicks=0),
        html.Div(id='button-output'),
        # Hidden div inside the app that stores the intermediate value
        html.Div(id='intermediate-value', style={'display': 'none'}),
        html.Div(id='graph')]),
    dcc.Tab(label='AFT', value="tab dos"),
    dcc.Tab(label='sensitivity analysis', value="tab-2", children=[
        html.Div([
            dcc.Upload(
                id='upload-data',
                children=html.Div([
                    'Drag and Drop or ',
                    html.A('Select'),
                    ' HeFTy files'
                ]),
                style={
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
            ),
            html.Div(id='output-data-upload'),
        ])
    ]
    )])
])


def parse_contents(contents, filename, date):
    content_type, content_string = contents.split(',')

    decoded = base64.b64decode(content_string)
    try:
        if 'csv' in filename:
            # Assume that the user uploaded a CSV file
            df = pd.read_csv(
                io.StringIO(decoded.decode('utf-8')))
        elif 'xls' in filename:
            # Assume that the user uploaded an excel file
            df = pd.read_excel(io.BytesIO(decoded))
        elif 'txt' in filename:
            # default no. of constraints in HeFTy is two
            n_extra_constraints = 0 
            min_times = np.array([])
            max_times = np.array([])
            min_temp = np.array([])
            max_temp = np.array([])
            # default HeFTy line for envelope
            default_envelope_ind = 6 

            # open file and loop thru lines
            with open(filename) as f:
                # lines are strings
                for (ind,line) in enumerate(f):
                    if ind>1:
                        line_split = line.split()
                        
                        if line_split[0].isdigit():
                            # get constraint box parameters
                            line_arr = np.array(line_split).astype(float)
                            max_times = np.append(min_times, line_arr[1])
                            min_times = np.append(min_times, line_arr[2])
                            max_temp = np.append(min_times, line_arr[3])
                            min_temp = np.append(min_times, line_arr[4])

                            # increment if more than default number of constraints
                            if ind>3:
                                n_extra_constraints += 1

                        # once constraints gotten get envelope of good and acceptable fits
                        else:    
                            if ind == default_envelope_ind+n_extra_constraints:
                                good_time = np.array(line_split[3:]).astype(float)
                            if ind== default_envelope_ind+n_extra_constraints+1:
                                good_hi = np.array(line_split[4:]).astype(float)
                            if ind== default_envelope_ind+n_extra_constraints+2:
                                good_lo = np.array(line_split[4:]).astype(float)
                            if ind == default_envelope_ind+n_extra_constraints+3:
                                acc_time = np.array(line_split[3:]).astype(float)
                            if ind == default_envelope_ind+n_extra_constraints+4:
                                acc_hi = np.array(line_split[4:]).astype(float)
                            if ind == default_envelope_ind+n_extra_constraints+5:
                                acc_lo = np.array(line_split[4:]).astype(float)
            # close file at end
            f.close()

    except Exception as e:
        print(e)
        return html.Div([
            'There was an error processing this file.'
        ])

    return html.Div([
        html.H5(filename),
        html.H6(datetime.datetime.fromtimestamp(date)),
        html.H4(good_lo),
        # dash_table.DataTable(
        #     data=df.to_dict('records'),
        #     columns=[{'name': i, 'id': i} for i in df.columns]
        # ),

        html.Hr(),  # horizontal line

        # For debugging, display the raw contents provided by the web browser
        html.Div('Raw Content'),
        html.Pre(contents[0:200] + '...', style={
            'whiteSpace': 'pre-wrap',
            'wordBreak': 'break-all'
        })
    ])


@app.callback(Output('output-data-upload', 'children'),
              Input('upload-data', 'contents'),
              dash.dependencies.State('upload-data', 'filename'),
              dash.dependencies.State('upload-data', 'last_modified'))
def update_output(list_of_contents, list_of_names, list_of_dates):
    if list_of_contents is not None:
        children = [
            parse_contents(c, n, d) for c, n, d in
            zip(list_of_contents, list_of_names, list_of_dates)]
        return children


@app.callback(
    dash.dependencies.Output('button-output', 'children'),
    [dash.dependencies.Input('submit-val', 'n_clicks')])
def update_output_text(n_clicks):
    payload = {'name': ' Ron', 'lastName': 'Ericsson'}
    r = requests.post("https://tdash.thermochron.org", json=payload)
    return 'The input value was {}.'.format(r.text)


if __name__ == '__main__':
    app.run_server(debug=True)
# port=8050,
#        host='0.0.0.0' 
#
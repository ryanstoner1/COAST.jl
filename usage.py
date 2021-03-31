import coast_app
import io
import dash
import base64
import requests
import datetime
import dash_auth
import dash_table
import txt_read_preprocess
import pandas as pd
import numpy as np
from SALib.analyze import sobol
from dash.dependencies import Input, Output
import dash_html_components as html
import dash_core_components as dcc

# Password for users
VALID_USERNAME_PASSWORD_PAIRS = {
    'thermo': 'Apatite3'
}
external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']

app = dash.Dash(__name__, external_stylesheets=external_stylesheets,title='COAST')
server = app.server
auth = dash_auth.BasicAuth(
    app,
    VALID_USERNAME_PASSWORD_PAIRS
)

app.layout = html.Div([dcc.Tabs(id='tabs-example', value='tab-1', children=[
    dcc.Tab(label='forward model', children=[
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
    dcc.Tab(label='inverse model', value="tab dos"),
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
            default_envelope_ind = 6 
            decoded = decoded.splitlines()

            # extract user-defined bounding boxes on T-t paths
            (bound_box, n_extra_constraints, decoded_shortened) = txt_read_preprocess.extract_Tt_constraints(
                default_envelope_ind, decoded)
            (max_times, min_times, max_temp, min_temp) = bound_box

            # get upper and lower limits for good and acceptable bounds in HeFTy
            (good_acc_bounds, decoded_shortened) = txt_read_preprocess.extract_Tt_bounds(decoded_shortened)
            (good_time, good_hi, good_lo, acc_time, acc_hi, acc_lo) = good_acc_bounds

            # extract good and acceptable path temperatures in hefty
            # at good and acceptable time bounds
            (dates, acc_temp_interp, good_temp_interp) = txt_read_preprocess.interp_Tt_finer_scale(
                good_time, acc_time, decoded_shortened)
            

    except Exception as e:
        print(e)
        return html.Div([
            'There was an error processing this file.'
        ])

    return html.Div([
        html.H5(filename),
        html.H6("Data loaded successfully!"),
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
    payload = {'name': 'test var'}
    r = requests.post("https://api.thermochron.org", json=payload)
    return 'The input value was {}.'.format(r.text)


if __name__ == '__main__':
    app.run_server( port=8050,
        host='0.0.0.0' )

#
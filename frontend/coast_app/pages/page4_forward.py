import dash
import dash_html_components as html
import dash_core_components as dcc

import requests
from app import app
from flask import request
from dash.exceptions import PreventUpdate
from dash.dependencies import Input, Output

import coast_app 
page_4_layout = html.Div([
    html.Div([coast_app.CoastApp(
            id='input',
            value='my-value',
            label='[10,20]'
    ),
    ]),
    html.Div(["Input: ",
                dcc.Input(id='my-input', value=90, type='number')]),
    html.Button('Submit', id='submit-val', n_clicks=0),
    html.Div(id='button-output'),
    # Hidden div inside the app that stores the intermediate value
    html.Div(id='intermediate-value', style={'display': 'none'}),
    html.Div(id='graph'),
    dcc.Input(
            id="input-request",
            placeholder="idtest",
        ),
    html.Div(id='target'),
]) 

@app.callback(
    dash.dependencies.Output('button-output', 'children'),
    [dash.dependencies.Input('submit-val', 'n_clicks')])
def update_output_text(n_clicks):
    payload = {'name': 'response','lastName': ' from Julia!'}
    r = requests.post("https://api.thermochron.org", json=payload)
    return 'Testing diffusion component working . . . {}.'.format(r.text)


@app.callback(Output('target', 'children'), [Input('input-request', 'value')])
def get_ip(value):
    return html.Div(request.remote_addr)
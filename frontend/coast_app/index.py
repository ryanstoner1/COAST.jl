# external dependencies
import io
import dash
import json
import base64
import chaospy 
import requests
import datetime
import dash_auth
import dash_table
import numpy as np
import pandas as pd
import plotly.express as px
import dash_table.FormatTemplate as FormatTemplate
import dash_html_components as html
import dash_core_components as dcc

from dash_table.Format import Sign
from dash.exceptions import PreventUpdate
from dash.dependencies import Input, Output, State
from collections import OrderedDict
from chaospy.example import coordinates, exponential_model, distribution
import dash_bootstrap_components as dbc
# internal: COAST
from pages import page1_about as page1
from pages import page2_sensitivities as page2
from pages import page3_inverse as page3
from pages import page4_forward as page4
import sensitivity_analysis
import coast_app
import txt_read_preprocess
from app import app

# Password for users
VALID_USERNAME_PASSWORD_PAIRS = {
    'thermo': 'Apatite3'
}

auth = dash_auth.BasicAuth(
    app,
    VALID_USERNAME_PASSWORD_PAIRS
)
server = app.server
app.layout = html.Div([
    dcc.Store(id='session'),
    dcc.Location(id='url', refresh=False),
    html.Div(
        id="tabs_holder",
        children=[dcc.Tabs(id="tabs", value='/page-1')]  # Defaults http://127.0.0.1:8050/ to http://127.0.0.1:8050/page-1. Otherwise, set value=None
    ),

    html.Div(id='page-content'),
])

@app.callback([Output('page-content', 'children'),
               Output('tabs_holder', 'children')],
              [Input('url', 'pathname')])
def display_page(pathname):
    tabs = [
        dcc.Tabs(
            id="tabs",
            value=pathname,
            children=[
                dcc.Tab(label='About', value='/page-1'),
                dcc.Tab(label='sensitivity analysis', value='/page-2'),
                dcc.Tab(label='inverse modeling', value='/page-3'),
                dcc.Tab(label='forward modeling', value='/page-4'),
            ]
        )
    ]
    if pathname == '/page-1':
        return page1.page_1_layout, tabs
    elif pathname == '/page-2':
        return page2.page_2_layout, tabs
    elif pathname == '/page-3':
        return page3.page_3_layout, tabs
    elif pathname == '/page-4':
        return page4.page_4_layout, tabs
    else:
        return html.Div([html.H1('Error 404 - Page not found')])

@app.callback(Output('url', 'pathname'),
              [Input('tabs', 'value')])
def tab_updates_url(value):
    return value

if __name__ == '__main__':
    app.run_server( port=8050,debug=False)
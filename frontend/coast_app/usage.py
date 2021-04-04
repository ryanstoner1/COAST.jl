# external dependencies
import io
import dash
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
import coast_app
import sensitivity_analysis
import txt_read_preprocess

# Password for users
VALID_USERNAME_PASSWORD_PAIRS = {
    'thermo': 'Apatite3'
}
external_stylesheets = [dbc.themes.BOOTSTRAP]

app = dash.Dash(__name__, external_stylesheets=external_stylesheets,title='COAST',suppress_callback_exceptions=True)
server = app.server
auth = dash_auth.BasicAuth(
    app,
    VALID_USERNAME_PASSWORD_PAIRS
)

app.layout = html.Div([
    dcc.Store(id='session'),
    dcc.Location(id='url', refresh=False),
    html.Div(
        id="tabs_holder",
        children=[dcc.Tabs(id="tabs", value='/page-1')]  # Defaults http://127.0.0.1:8050/ to http://127.0.0.1:8050/page-1. Otherwise, set value=None
    ),

    html.Div(id='page-content'),
])

df_typing_formatting = pd.DataFrame(OrderedDict([
    ('date', np.zeros(29)),
    ('error', np.zeros(29)),
]))

df2 = pd.DataFrame(OrderedDict([
    ('date', np.zeros(29)),
    ('error', np.zeros(29)),
]))

df3 = pd.DataFrame(OrderedDict([
    ('date', np.zeros(29)),
    ('error', np.zeros(29)),
]))

page_1_layout = html.Div([
    html.Div([
    html.H6("COAST program description")]),
    dcc.Link('Go to Page 1', href='/page-1'),
    html.Br(),
    dcc.Link('Go to Page 2', href='/page-2'),
])

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
                dbc.DropdownMenuItem("U-Pb Apatite ", id="ap-button",href="/page-3"),
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
    ])
]) 

page_3_layout = html.Div([
    html.H1('Inverse modeling'),
    dbc.FormGroup(
        [
            dbc.Label("Diffusion Activation energy"),
            html.P(children=[
                html.Strong('Take Home Pay Total: '),
                html.Span("snuggle")
            ]),
            html.Div([ 
                html.Span("D",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('0'),
                dcc.Input(placeholder=" . . .", id="D0-in", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span("E",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('a'),
                dcc.Input(placeholder="Ea (kJ)", id="Ea-in", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            ],style = {'display': 'block'}),
            html.Div([
                html.Span("n",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('steps'),
                dcc.Input(placeholder="number", id="n-segs", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span('\u0394',style = {'display': 'inline-block','margin-left':'10px'}),
                html.Sub('r'),
                dcc.Input(placeholder="time", id="time", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            ],style = {'display': 'block'}),
            dbc.FormText("Type the activation energy in the box above"),
        ]
    ),
    dcc.Link('Go to Page 1', href='/page-1'),
    html.Br(),
    dcc.Link('Go to Page 2', href='/page-2'),
    html.H2("GB119C-10"),
    dash_table.DataTable(
        id='typing_formatting_1',
        data=df_typing_formatting.to_dict('records'),
        columns=[{
            'id': 'average_04_2018',
            'name': 'distance',
            'type': 'numeric'
        }, {
            'id': 'change_04_2017_04_2018',
            'name': 'concentration',
            'type': 'numeric'
        }],
        editable=True
    ),
    html.H2("GB119C-32"),
    dash_table.DataTable(
        id='typing_formatting_2',
        data=df2.to_dict('records'),
        columns=[{
            'id': 'average_04_2018',
            'name': 'distance',
            'type': 'numeric'
        }, {
            'id': 'change_04_2017_04_2018',
            'name': 'concentration',
            'type': 'numeric'
        }],
        editable=True
    ),
    html.H2("GB119C-42"),
    dash_table.DataTable(
        id='typing_formatting_3',
        data=df3.to_dict('records'),
        columns=[{
            'id': 'average_04_2018',
            'name': 'distance',
            'type': 'numeric'
        }, {
            'id': 'change_04_2017_04_2018',
            'name': 'concentration',
            'type': 'numeric'
        }],
        editable=True
    ),    
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

# output the stored clicks in the table cell.
@app.callback(Output('D0-in', 'value'),
                Output('Ea-in', 'value'),
                # Since we use the data prop in an output,
                # we cannot get the initial data on load with the data prop.
                # To counter this, you can use the modified_timestamp
                # as Input and the data as State.
                # This limitation is due to the initial None callbacks
                # https://github.com/plotly/dash-renderer/pull/81
                Input('session', 'modified_timestamp'),
                State('session', 'data'))
def on_data(ts, data):
    if ts is None:
        raise PreventUpdate

    data = data or {}

    return data.get('D0', 0),data.get('Ea', 0),


page_4_layout = html.Div([
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
    html.Div(id='graph'),
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
        return page_1_layout, tabs
    elif pathname == '/page-2':
        return page_2_layout, tabs
    elif pathname == '/page-3':
        return page_3_layout, tabs
    elif pathname == '/page-4':
        return page_4_layout, tabs
    else:
        return html.Div([html.H1('Error 404 - Page not found')])


@app.callback(Output('url', 'pathname'),
              [Input('tabs', 'value')])
def tab_updates_url(value):
    return value

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
        host='0.0.0.0' ,debug=True)

#
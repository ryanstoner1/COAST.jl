from app import app
from dash.exceptions import PreventUpdate
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
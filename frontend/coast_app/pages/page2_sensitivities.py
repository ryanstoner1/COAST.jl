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
    ]),
    dcc.Dropdown(
        id = 'dropdown-to-show_or_hide-element',
        options=[
            {'label': 'Show element', 'value': 'on'},
            {'label': 'Hide element', 'value': 'off'}
        ],
        value = 'off'
    ),

    # Create Div to place a conditionally visible element inside
    html.Div([
        # Create element to hide/show, in this case an 'Input Component'
        dcc.Input(
        id = 'element-to-hide',
        placeholder = 'something',
        value = 'Can you see me?',
        )
    ], style= {'visibility': 'hidden','display':'block'} # <-- This is the line that will be changed by the dropdown callback
    )
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

@app.callback(
   Output(component_id='element-to-hide', component_property='style'),
   [Input(component_id='dropdown-to-show_or_hide-element', component_property='value')])
def show_hide_element(visibility_state):  
    if visibility_state == 'on':
        return {'visibility': 'visible','display':'block'}
    if visibility_state == 'off':
        return {'visibility': 'hidden','display':'none'}

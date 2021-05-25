import dash
import numpy as np
import dash_html_components as html
import dash_core_components as dcc
import dash_bootstrap_components as dbc
import requests
from app import app
from flask import request
from dash.dash import no_update
from dash.exceptions import PreventUpdate
from dash.dependencies import Input, Output, State
import json
import coast_app 
page_4_layout = html.Div([
    html.Div(["Input: ",
                dcc.Input(id='my-input', value=90, type='number')]),
    html.Button('Submit', id='submit-val', n_clicks=0),
    html.Div(id='button-output'),
    # Hidden div inside the app that stores the intermediate value
    html.Div(id='intermediate-value', style={'display': 'none'}),
    html.Div(id='test_js'),
    html.Div(id='target'),
    dcc.Dropdown(
        id = 'dropdown-to-show_or_hide-element_p4',
        options=[
            {'label': 'Choose data type', 'value': 'off'},
            {'label': 'single grain', 'value': 'on1'},
            {'label': 'zonation data', 'value': 'on2'}
        ],
        value = 'off'
    ),
    html.Div([
        html.H3("General diffusion parameters"),
        # Create element to hide/show, in this case an 'Input Component'
        html.Div([ 
            html.Span("D",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('0'),
            dcc.Input(placeholder=" . . .", id="D0-in-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("E",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('a'),
            dcc.Input(placeholder="Ea (kJ)", id="Ea-in-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Br(),
            dcc.Checklist(
                options=[
                    {'label': ' Radiation damage?', 'value': 'rad'},
                ],style = {'display': 'inline-block','margin-left':'10px','width': '20em'},
                value=[],
                id = "is-rad-damage"
            ),
            dbc.DropdownMenu(
                label="Diffusion type",
                children=[
                    dbc.DropdownMenuItem("(U-Th)/He Apatite (Flowers, 2009)", id="ap-button-flower09"),
                    dbc.DropdownMenuItem("U-Pb Rutile (Cherniak, 2000)",id= "rut-button-cherniak00"),
                    dbc.DropdownMenuItem("U-Th/He Apatite"),
                    dbc.DropdownMenuItem("U-Th/He Zircon"),
                    dbc.DropdownMenuItem("U-Th/He Titanite"),
                ],
            ),
        ],style = {'display': 'block'}),
        html.H3("Date data"),
        html.Div([ 
            html.Span("rad",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('grain'),  
            dcc.Input(placeholder="(um)", id="rad-in-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("U",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('238'),  
            dcc.Input(placeholder="(ppm)", id="u38-in-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("Th",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('232'),  
            dcc.Input(placeholder="(ppm)", id="th32-in-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),       
        ],style = {'display': 'block'}), 
        html.Br(),
        html.Div([
            html.H3("Radiation damage parameters"),
            html.Div([
            html.Span("\u03B1",style = {'display': 'inline-block','margin-left':'10px'}),  
            dcc.Input(placeholder="p1", id="rad-p1", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("c",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('0'), 
            dcc.Input(placeholder="p2", id="rad-p2", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("c",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('1'), 
            dcc.Input(placeholder="p3", id="rad-p3", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("c",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('2'), 
            dcc.Input(placeholder="p4", id="rad-p4", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("c",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('3'), 
            dcc.Input(placeholder="p5", id="rad-p5", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            html.Span("rmr",style = {'display': 'inline-block','margin-left':'10px'}), 
            html.Sub('0'), 
            dcc.Input(placeholder="p6", id="rad-p6", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),    
            ],style= {'display':'inline-block'}),
            html.Div([
                html.Span("\u03B7",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('q'), 
                dcc.Input(placeholder="p7", id="rad-p7", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span("L",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('dist'), 
                dcc.Input(placeholder="p8", id="rad-p8", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span("\u03A8",style = {'display': 'inline-block','margin-left':'10px'}), # psi
                dcc.Input(placeholder="p9", id="rad-p9", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}), 
                html.Span("\u03A9",style = {'display': 'inline-block','margin-left':'10px'}), # omega
                dcc.Input(placeholder="p10", id="rad-p10", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),  
                html.Span("E",style = {'display': 'inline-block','margin-left':'10px'}), 
                html.Sub('trap'), 
                dcc.Input(placeholder="p11", id="rad-p11", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),                      
            ],style= {"vertical-align":"top",'display':'inline-block'}),
        ],style= {'visibility': 'hidden','display':'block'}, id="daam_hid_p4"),       
    ], style= {'visibility': 'hidden','display':'block'}, # <-- This is the line that will be changed by the dropdown callback
    id = "elem1hide_p4"),
    html.Div([
        # Create element to hide/show, in this case an 'Input Component'
        dcc.Input(
        id = 'elem2hide_p4',
        placeholder = 'taklimakan',
        value = 'TODO: single grain inversion',
        )
    ], style= {'visibility': 'hidden','display':'block'}, # <-- This is the line that will be changed by the dropdown callback
    ),
]) 

@app.callback(
    dash.dependencies.Output('test_js','children'),
    dash.dependencies.Input('my-input','value'),
    dash.dependencies.Input('rad-in-p4','value'),
    dash.dependencies.Input('u38-in-p4','value'),
    dash.dependencies.Input('th32-in-p4','value'),
    dash.dependencies.Input('rad-p1','value'),
    dash.dependencies.Input('rad-p2','value'),        
    dash.dependencies.Input('rad-p3','value'),
    dash.dependencies.Input('rad-p4','value'),
    dash.dependencies.Input('rad-p5','value'),
    dash.dependencies.Input('rad-p6','value'),    
    dash.dependencies.Input('rad-p7','value'),
    dash.dependencies.Input('rad-p8','value'),
    dash.dependencies.Input('rad-p9','value'),
    dash.dependencies.Input('rad-p10','value'),
    dash.dependencies.Input('rad-p11','value'),
    dash.dependencies.Input("Ea-in-p4","value"),
    dash.dependencies.Input("D0-in-p4","value"),
    )
def test_highcharts(val,
    rad,
    u38,
    th32,
    alpha,
    c0,
    c1,
    c2,
    c3,
    rmr0,
    eta_q,
    L_dist,
    psi,
    omega,
    Etrap,
    E_L,
    D0L_a2,
    ):
    args = locals()
    arg_dict = {key:('NaN' if value is None else value) for key, value in args.items()}
    print(arg_dict)
    return coast_app.CoastApp(
            id='input',
            value=str(val),
            label="[[0, 10]]",
            rad = '2',
            u38 = '3',
            th32 = '9',
            Etrap='3',
            alpha = '5',
            c0 = '2',
            c1 = '2', 
            c2 = '2',
            c3 = '2',
            rmr0='3',
            eta_q = '3',
            L_dist = '2', 
            psi = '2',
            omega = '2',
            E_L = '2',
            D0L_a2 = '2',
            
    )
    


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

@app.callback(
   [Output(component_id='elem1hide_p4', component_property='style'),
   Output(component_id='elem2hide_p4', component_property='style')],
   [Input(component_id='dropdown-to-show_or_hide-element_p4', component_property='value')])
def show_hide_element_p4(visibility_state):  
    if visibility_state == 'on1':
        return {'visibility': 'visible','display':'block'},{'visibility': 'hidden','display':'none'}
    if visibility_state == 'off':
        return {'visibility': 'hidden','display':'none'},{'visibility': 'hidden','display':'none'}
    if visibility_state == 'on2':
        return {'visibility': 'hidden','display':'none'},{'visibility': 'visible','display':'block'}

@app.callback(
    Output("daam_hid_p4", "style"),
    Input("is-rad-damage", component_property='value')
)
def show_rad_dam_p4(checked):
    if not checked:
        return {'visibility': 'hidden','display':'none'}
    else:
        return {'visibility': 'visible','display':'block'}

# @app.callback(Output("is-rad-damage",component_property='value'),Output('D0-in-p4', 'value'),Output('Ea-in-p4', 'value'),
#                 Input('rut-button-cherniak00', 'n_clicks'))
# def on_click_cherniak00(n_clicks):
#     if n_clicks is None:
#         # prevent the None callbacks is important with the store component.
#         # you don't want to update the store for nothing.
#         raise PreventUpdate

#     # Give a default data dict with 0 clicks if there's no data.
#     #data = data or {'D0': None, 'Ea': None}
#     #data['Ea'] = 250*1e3
#     #data['D0'] = 3.9*1e-10#data['clicks'] + 1
#     D0 = 3.9*1e-10
#     Ea = 250*1e3
#     uncheck_rad_damage = []
#     return uncheck_rad_damage,D0, Ea

@app.callback(
    [
        Output("is-rad-damage",component_property='value'),
        Output("rad-p1","value"),
        Output("rad-p2","value"),
        Output("rad-p3","value"),
        Output("rad-p4","value"),
        Output("rad-p5","value"),
        Output("rad-p6","value"),
        Output("rad-p7","value"),
        Output("rad-p8","value"),
        Output("rad-p9","value"),
        Output("rad-p10","value"),
        Output("rad-p11","value"),
        Output("Ea-in-p4","value"),
        Output("D0-in-p4","value"),
    ],
    Input('ap-button-flower09', 'n_clicks'),
    Input('rut-button-cherniak00', 'n_clicks'),
    prevent_initial_call=True)
def on_click_flowers09(n_clicks_flowers,n_clicks_cherniak):
    ctx = dash.callback_context

    if not ctx.triggered:
        button_id = 'No clicks yet'
        raise PreventUpdate
    else:
        button_id = ctx.triggered[0]['prop_id'].split('.')[0]
        if button_id=="rut-button-cherniak00":
            D0 = 3.9*1e-10
            Ea = 250*1e3
            uncheck_rad_damage = []

            return (uncheck_rad_damage, 
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    no_update,
                    Ea,
                    D0)
        elif button_id=="ap-button-flower09":
            check_rad_damage = ["rad"]
            alpha = 0.04672
            c0 = 0.39528
            c1 = 0.01073
            c2 = -65.12969
            c3 =  -7.91715
            rmr0 = 0.79
            eta_q = 0.91
            L_dist = 8.1*1e-4 # cm (!)
            psi = 1e-13
            omega = 1e-22
            Etrap = 34*1e3 # J/mol

            E_L = 122.3*1e3 # J/mol
            #L2 = 60*1e-4
            D0L_a2 = np.exp(9.733)#*L^2/L2^2)
            return (check_rad_damage, 
                    alpha,
                    c0,
                    c1,
                    c2,
                    c3,
                    rmr0,
                    eta_q,
                    L_dist,
                    psi,
                    omega,
                    Etrap,
                    E_L,
                    D0L_a2)


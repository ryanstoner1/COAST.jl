from app import app
import json
import dash_table
import requests
import pandas as pd
import numpy as np
from collections import OrderedDict
import dash_html_components as html
import dash_core_components as dcc
import dash_bootstrap_components as dbc
import sensitivity_analysis
from dash import callback_context
from dash.exceptions import PreventUpdate
from dash.dependencies import Input, Output, State, MATCH, ALL

page_3_layout = html.Div([
    html.H1('Inverse modeling'),
    dbc.FormGroup(
        [
            dbc.Label("Diffusion Activation energy"),
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
                html.Sub('samples'),
                dcc.Input(placeholder="number", id="n-samp", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span('n',style = {'display': 'inline-block','margin-left':'10px'}),
                html.Sub('tsteps'),
                dcc.Input(placeholder="count", id="nt", min=0, max=1e4,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span('time',style = {'display': 'inline-block','margin-left':'10px'}),
                html.Sub('beg'),
                dcc.Input(placeholder="(Ma)", id="t-beg", min=0, max=1e4,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span('time',style = {'display': 'inline-block','margin-left':'10px'}),
                html.Sub('end'),
                dcc.Input(placeholder="(Ma)", id="t-end", min=0, max=1e4,style = {'display': 'block','margin-left':'10px','width': '5em'}),
                html.Span('r',style = {'display': 'inline-block','margin-left':'10px'}),
                html.Sub('grain'),
                dcc.Input(placeholder="(um)", id="radius", min=0, max=1e8,style = {'display': 'block','margin-left':'10px','width': '5em'}),
            ],style = {'display': 'block'}),
            dbc.FormText("Type the activation energy in the box above"),
        ]
    ),

    dbc.Button("Process Data", id="table-button", className="mr-2"),
    html.Span(id="example-output", style={"vertical-align": "middle"}),
    html.Br(),
    dbc.Button("Process PCE", id="pce-button", className="mr-1"),
    html.Span(id="pce-output", style={"vertical-align": "middle"}),
    html.Br(),
    dbc.Button("Process zonation", id="zonation-button", className="mr-3"),
    html.Span(id="zon-output", style={"vertical-align": "middle"}),
    dcc.Dropdown(
        id = 'dropdown-to-show_or_hide-element',
        options=[
            {'label': 'Choose data type', 'value': 'off'},
            {'label': 'single grain', 'value': 'on'},
            {'label': 'zonation data', 'value': 'on2'}
        ],
        value = 'off'
    ),
    # Create Div to place a conditionally visible element inside
    html.Div([
        # Create element to hide/show, in this case an 'Input Component'
        dcc.Input(
        id = 'element-to-hide',
        placeholder = 'something',
        value = 'TODO: single grain inversion',
        )
    ], style= {'visibility': 'hidden','display':'block'} # <-- This is the line that will be changed by the dropdown callback
    ),
    # Create Div to place a conditionally visible element inside
    html.Div([
        # Create element to hide/show, in this case an 'Input Component'        
        html.Div([
            html.Div('Sample name (optional)'),
            dcc.Input(id="new-item"),
            html.Div('Number rows'),
            dcc.Input(placeholder=" . . .", id="nrows",type="number", min=0, max=75,step=1,style = {'display': 'block','margin-left':'0px','width': '5em'}),
            dbc.Button("Add", id="add"),
            dbc.Button("Clear Selected", id="clear-done"),
            dbc.Button("Single inversion", id="invert-1"),
            html.Div(id="list-container"),
            html.Div(id="table-container"),
            html.Div(id="totals"),
            html.Div(id="table_slice"),
            ],id="element-to-hide2"
        ),
    ], style= {'visibility': 'hidden','display':'block'} # <-- This is the line that will be changed by the dropdown callback
    ),
])

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

    return data.get('D0', 0),data.get('Ea', 0)



@app.callback(
    Output("pce-output", "children"), [Input("pce-button", "n_clicks")],Input('n-samp',"value")
)
def on_button_click(n,nsamp):
    if n is None:
        return "Not clicked."
    else:
        nsamp = int(nsamp)
        in_means = [20.0,10.0]
        in_stds = [20.0,10.0]
        distributions = sensitivity_analysis.get_input_distributions(in_means, in_stds)
        samples = distributions.sample(nsamp, rule="halton")
        # evaluations = numpy.array([exponential_model(sample,coordinates=coordinates)
        #     for sample in samples.T])

        return "pce success {}!".format(nsamp)

@app.callback(
   [Output(component_id='element-to-hide', component_property='style'),
   Output(component_id='element-to-hide2', component_property='style')],
   [Input(component_id='dropdown-to-show_or_hide-element', component_property='value')])
def show_hide_element_p3(visibility_state):  
    if visibility_state == 'on':
        return {'visibility': 'visible','display':'block'},{'visibility': 'hidden','display':'none'}
    if visibility_state == 'off':
        return {'visibility': 'hidden','display':'none'},{'visibility': 'hidden','display':'none'}
    if visibility_state == 'on2':
        return {'visibility': 'hidden','display':'none'},{'visibility': 'visible','display':'block'}

style_todo = {"display": "inline", "margin": "10px"}
style_done = {"textDecoration": "line-through", "color": "#888"}
style_done.update(style_todo)


@app.callback(
    [
        Output("list-container", "children"),
        Output("new-item", "value"),
    ],
    [
        Input("add", "n_clicks"),
        Input("new-item", "n_submit"),
        Input("clear-done", "n_clicks")
    ],
    [
        State("new-item", "value"),
        State("nrows","value"),
        State({"index2": ALL}, 'data'),
        State({"index": ALL}, "children"),
        State({"index": ALL, "type": "done"}, "value")
    ]
)
def edit_list(add, add2, clear, new_item, nrows_table, table_data, items, items_done):
    

    triggered = [t["prop_id"] for t in callback_context.triggered]
    adding = len([1 for i in triggered if i in ("add.n_clicks", "new-item.n_submit")])
    clearing = len([1 for i in triggered if i == "clear-done.n_clicks"])
    new_spec = [
        (datum, text, done) for datum, text, done in zip(table_data, items, items_done)
        if not (clearing and done)
    ]
    
    if adding:
        new_spec.append(([{'distance':0.0,'date':0.0,'error':0.0}]*nrows_table,new_item, []))

    new_list = [
        html.Div([
            html.Div([html.H3(text)], id={"index": i}, style=style_done if done else style_todo),
            dcc.Checklist(
                id={"index": i, "type": "done"},
                options=[{"label": "", "value": "done"}],
                value=done,
                style={"display": "inline"},
                labelStyle={"display": "inline"}
            ),
            dash_table.DataTable(
                id={"index2": i},
                columns=[{
                    'id': 'distance',
                    'name': 'distance',
                    'type': 'numeric'
                }, {
                    'id': 'date',
                    'name': 'date',
                    'type': 'numeric'
                }, {
                    'id': 'error',
                    'name': 'error',
                    'type': 'numeric'
                }],
                data=datum,
                editable=True,
                row_deletable=True
            ),   
        ], style={"clear": "both"})
        for i, (datum, text, done) in enumerate(new_spec)
    ]
    
    return [new_list, "" if adding else new_item]


@app.callback(
    Output({"index": MATCH}, "style"),
    Input({"index": MATCH, "type": "done"}, "value")
)
def mark_done(done):
    
    return style_done if done else style_todo


@app.callback(
    Output("totals", "children"),
    Input({"index": ALL, "type": "done"}, "value")
)
def show_totals(done):
    
    count_all = len(done)
    count_done = len([d for d in done if d])
    result = "{} of {} tables selected".format(count_done, count_all)
    return result

# gets called each time button is clicked
@app.callback(
    Output("table_slice","children"),
    Input("invert-1","n_clicks"),
    state=[State({"index2": ALL}, 'data'),
    State({"index2": ALL}, 'columns'),
    State('Ea-in', 'value'),
    State('D0-in', 'value'),
    State('nt','value'),
    State('t-beg', 'value'),
    State('t-end', 'value'),
    State('radius','value')]
)
def show_slice(n,table_data,table_columns,Ea,D0,nt,t_beg,t_end,radius):
    if n is None:
        return "not called yet!"
    else:
        list_dfs = []
        for (columns,table) in zip(table_columns, table_data):
            filtered_table = []
            non_numerics = 0
            
            for row in table:
                try:
                    new_row = {}
                    for (key,val) in row.items():
                        new_row[key] = float(val)
                    filtered_table.append(new_row)
                except:
                    non_numerics += 1
            
            print("Processed table & filtered {} non-numeric values.".format(non_numerics))

            df = pd.DataFrame(filtered_table, columns=[c['name'] for c in columns])
            np_df = df.to_numpy()
            list_df = np_df.tolist()
            list_dfs.append(list_df)

        payload = {"Ea":Ea,"D0":D0,"id":23,"function_to_run":"zonation",
            "data":list_dfs,"t_end":t_end,"t_beg":t_beg,"radius":radius,"Nt":nt}
        r = requests.post("http://0.0.0.0:8000/model", json=payload)
        print(r.text)
        return str(table_data)



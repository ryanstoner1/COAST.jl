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
d1 = pd.DataFrame(OrderedDict([
    ('distance', [0]*29),
    ('date', [0]*29),
    ('error', [0]*29),
]))

df2 = pd.DataFrame(OrderedDict([
    ('distance', [0]*29),
    ('date', np.zeros(29)),
    ('error', np.zeros(29)),
]))

df3 = pd.DataFrame(OrderedDict([
    ('distance', [0]*29),
    ('date', np.zeros(29)),
    ('error', np.zeros(29)),
]))

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
        value = 'Can you see me?',
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
            html.Div(id="list-container"),
            html.Div(id="table-container"),
            html.Div(id="totals")
            ],id="element-to-hide2"
        ),
    ], style= {'visibility': 'hidden','display':'block'} # <-- This is the line that will be changed by the dropdown callback
    ),
    html.H2("GB119C-10"),
    dash_table.DataTable(
        id='t1',
        data=d1.to_dict('records'),
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
        editable=True
    ),
    html.Div(id='t1_out'),
    html.H2("GB119C-32"),
    dash_table.DataTable(
        id='t2',
        data=df2.to_dict('records'),
        columns=[{
            'id': 'distance',
            'name': 'distance',
            'type': 'numeric'
        },{
            'id': 'date',
            'name': 'date',
            'type': 'numeric'
        }, {
            'id': 'error',
            'name': 'error',
            'type': 'numeric'
        }],
        editable=True,
        row_deletable=True
    ),
    html.H2("GB119C-42"),
    dash_table.DataTable(
        id='t3',
        data=df3.to_dict('records'),
        columns=[{
            'id': 'distance',
            'name': 'distance',
            'type': 'numeric'
        },{
            'id': 'date',
            'name': '06/38',
            'type': 'numeric'
        }, {
            'id': 'error',
            'name': '2 sigma (abs)',
            'type': 'numeric'
        }],
        editable=True
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
    Output("example-output", "children"), [Input("table-button", "n_clicks")],Input('t1', 'data'),
    Input('t1', 'columns'),Input('Ea-in', 'value'),Input('D0-in', 'value'),
)
def on_button_click(n,rows1,columns1,Ea,D0):
    if n is None:
        return "Not clicked."
    else:
        n_t_segs = 6
        df1 = pd.DataFrame(rows1, columns=[c['name'] for c in columns1])
        distance = (df1["distance"].tolist())
        dr = (distance[2] - distance[1])/1e6
        Lmax = max(distance)/1e6
        dates = df1["date"].tolist()
        tmax = max(dates)
        tmin = min(dates)
        dates= [dates]
        errors =  [df1["error"].tolist()]
        print(str(dates))
        payload = {"function_to_run":"zonation","zon_n_t_segs": str(n_t_segs),
            "Ea":str(Ea),"D0":str(D0),"U38Pb06":str(dates),"sigU38Pb06":str(errors),"Lmax":str(Lmax),"tmax":str(tmax),
        "tmin":str(tmin),"dr":str(dr),"distance":str(distance)}

        r = requests.post("http://api.thermochron.org/model", json=payload)
        print(r.text)
        return "200"

@app.callback(
    Output('t1_out', 'children'),
    Input('t1', 'data'),
    Input('t1', 'columns'))
def display_output(rows, columns):
    if rows is None:
        raise PreventUpdate
    df = pd.DataFrame(rows, columns=[c['name'] for c in columns])
    result = json.dumps(df["date"].tolist())
    return result

@app.callback(
   [Output(component_id='element-to-hide', component_property='style'),
   Output(component_id='element-to-hide2', component_property='style')],
   [Input(component_id='dropdown-to-show_or_hide-element', component_property='value')])
def show_hide_element(visibility_state):  
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
    Output('zon-output', 'children'),
    [Input("zonation-button", "n_clicks")],
    state=[State('t1', 'data'),
    State('t1', 'columns'),
    State('t2', 'data'),
    State('t2', 'columns'),
    State('Ea-in', 'value'),
    State('D0-in', 'value'),
    State('nt','value'),
    State('t-beg', 'value'),
    State('t-end', 'value'),
    State('radius','value')])
def display_output(n,rows1, columns1, rows2, columns2,Ea,D0,nt,t_beg,t_end,radius):
    if rows1 is None:
        raise PreventUpdate
    
    if n is None:
        return "not called yet!"
    else:
        df1 = pd.DataFrame(rows1, columns=[c['name'] for c in columns1])
        df2 = pd.DataFrame(rows2, columns=[c['name'] for c in columns2])
        np_df1 = df1.to_numpy()
        list_df1 = np_df1.tolist()
        np_df2 = df2.to_numpy()
        list_df2 = np_df2.tolist()
        list_dfs = [list_df1, list_df2]
        Ea = float(Ea)
        result = json.dumps(df1["date"].tolist() + df2["date"].tolist())
        payload = {"Ea":Ea,"D0":D0,"id":23,"function_to_run":"zonation",
            "data":list_dfs,"t_end":t_end,"t_beg":t_beg,"radius":radius,"Nt":nt}
        r = requests.post("http://api.thermochron.org/model", json=payload)
        print(r.text)

        return result
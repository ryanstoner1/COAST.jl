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
from dash.exceptions import PreventUpdate
from dash.dependencies import Input, Output, State
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
        editable=True
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
        r = requests.post("http://0.0.0.0:8000/model", json=payload)
        print(r.text)

        return result
import coast_app
import dash
import dash_auth
from dash.dependencies import Input, Output
import dash_html_components as html
import dash_core_components as dcc

# Keep this out of source code repository - save in a file or a database
VALID_USERNAME_PASSWORD_PAIRS = {
    'thermo': 'Apatite3'
}

app = dash.Dash(__name__)
auth = dash_auth.BasicAuth(
    app,
    VALID_USERNAME_PASSWORD_PAIRS
)

app.layout = html.Div([dcc.Tabs(id='tabs-example', value='tab-1', children=[
    dcc.Tab(label='He Diffusion', children=[
        coast_app.CoastApp(
            id='input',
            value='my-value',
            label='[10,20]'
        ),
        html.Div(["Input: ",
                  dcc.Input(id='my-input', value=90, type='number')]),
        html.Div(id='output'),
        # Hidden div inside the app that stores the intermediate value
        html.Div(id='intermediate-value', style={'display': 'none'}),
        html.Div(id='graph')]),
    dcc.Tab(label='AFT', value="tab dos"),
    dcc.Tab(label='Vitrinite', value="tab-2", children=[
        dcc.Tab(label='foo', value="tab tres"),
        dcc.Tab(label='bar', value="tab quatro")
    ]
    )])
])


if __name__ == '__main__':
    app.run_server(debug=True)

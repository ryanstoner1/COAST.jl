import dash
import dash_bootstrap_components as dbc
external_stylesheets = [dbc.themes.BOOTSTRAP]

app = dash.Dash(__name__, external_stylesheets=external_stylesheets,title='COAST',suppress_callback_exceptions=True)
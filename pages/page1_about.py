# page 1
from app import app
import dash_html_components as html
import dash_core_components as dcc

page_1_layout = html.Div([
    html.H4("Motivation"),
    html.Br(),
    html.P("Unfortunately, we often only know the relative contributions of each of these sources of uncertainty qualitatively. Quantifying relative contributions of error is currently very computationally challenging with existing methods. The following questions are computationally challenging to answer quantitatively:",style={"padding-left": "10px"}),
    html.I("How does our uncertainty in dates propagate to uncertainty in thermal histories?"),
    html.Br(),
    html.Br(),
    html.I("How much of my uncertainty is because our problem is underconstrained?"),
    html.Br(),
    html.Br(),
    html.I("How does uncertainty in my diffusion or radiation damage model affect my thermal histories?"),
    html.Br(),
    html.Br(),
    html.H4("About this Package"),
    html.Br(),
    html.P("The inputs in this package are the same as existing thermochronology software packages for thermal history."),
    html.P("The three primary goals of this package are to:"),
    html.Br(),
    html.I("Quantify the relative contribution of "),
    dcc.Link('Go to Page 2', href='/page-2'),    
    html.Br(),
    dcc.Link('Go to Page 3', href='/page-3'),
    html.H6("Constrained Optimization and Sensitivity for Thermochronology (COAST)",style={'53-size': '20px'}),
])
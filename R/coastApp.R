# AUTO GENERATED FILE - DO NOT EDIT

coastApp <- function(id=NULL, D0L_a2=NULL, E_L=NULL, Etrap=NULL, L_dist=NULL, alpha=NULL, c0=NULL, c1=NULL, c2=NULL, c3=NULL, eta_q=NULL, label=NULL, omega=NULL, psi=NULL, rad=NULL, rmr0=NULL, th32=NULL, u38=NULL, value=NULL) {
    
    props <- list(id=id, D0L_a2=D0L_a2, E_L=E_L, Etrap=Etrap, L_dist=L_dist, alpha=alpha, c0=c0, c1=c1, c2=c2, c3=c3, eta_q=eta_q, label=label, omega=omega, psi=psi, rad=rad, rmr0=rmr0, th32=th32, u38=u38, value=value)
    if (length(props) > 0) {
        props <- props[!vapply(props, is.null, logical(1))]
    }
    component <- list(
        props = props,
        type = 'CoastApp',
        namespace = 'coast_app',
        propNames = c('id', 'D0L_a2', 'E_L', 'Etrap', 'L_dist', 'alpha', 'c0', 'c1', 'c2', 'c3', 'eta_q', 'label', 'omega', 'psi', 'rad', 'rmr0', 'th32', 'u38', 'value'),
        package = 'coastApp'
        )

    structure(component, class = c('dash_component', 'list'))
}

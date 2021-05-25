# AUTO GENERATED FILE - DO NOT EDIT

from dash.development.base_component import Component, _explicitize_args


class CoastApp(Component):
    """A CoastApp component.
ExampleComponent is an example component.
It takes a property, `label`, and
displays it.
It renders an input with the property `value`
which is editable by the user.

Keyword arguments:

- id (string; optional):
    The ID used to identify this component in Dash callbacks.

- D0L_a2 (string; optional):
    The value displayed in the input.

- E_L (string; optional):
    The value displayed in the input.

- Etrap (string; optional):
    The value displayed in the input.

- L_dist (string; optional):
    The value displayed in the input.

- alpha (string; optional):
    The value displayed in the input.

- c0 (string; optional):
    The value displayed in the input.

- c1 (string; optional):
    The value displayed in the input.

- c2 (string; optional):
    The value displayed in the input.

- c3 (string; optional):
    The value displayed in the input.

- eta_q (string; optional):
    The value displayed in the input.

- label (string; required):
    A label that will be printed when this component is rendered.

- omega (string; optional):
    The value displayed in the input.

- psi (string; optional):
    The value displayed in the input.

- rad (string; optional):
    The value displayed in the input.

- rmr0 (string; optional):
    The value displayed in the input.

- th32 (string; optional):
    The value displayed in the input.

- u38 (string; optional):
    The value displayed in the input.

- value (string; optional):
    The value displayed in the input."""
    @_explicitize_args
    def __init__(self, id=Component.UNDEFINED, label=Component.REQUIRED, value=Component.UNDEFINED, rad=Component.UNDEFINED, u38=Component.UNDEFINED, th32=Component.UNDEFINED, Etrap=Component.UNDEFINED, alpha=Component.UNDEFINED, c0=Component.UNDEFINED, c1=Component.UNDEFINED, c2=Component.UNDEFINED, c3=Component.UNDEFINED, rmr0=Component.UNDEFINED, eta_q=Component.UNDEFINED, L_dist=Component.UNDEFINED, psi=Component.UNDEFINED, omega=Component.UNDEFINED, E_L=Component.UNDEFINED, D0L_a2=Component.UNDEFINED, **kwargs):
        self._prop_names = ['id', 'D0L_a2', 'E_L', 'Etrap', 'L_dist', 'alpha', 'c0', 'c1', 'c2', 'c3', 'eta_q', 'label', 'omega', 'psi', 'rad', 'rmr0', 'th32', 'u38', 'value']
        self._type = 'CoastApp'
        self._namespace = 'coast_app'
        self._valid_wildcard_attributes =            []
        self.available_properties = ['id', 'D0L_a2', 'E_L', 'Etrap', 'L_dist', 'alpha', 'c0', 'c1', 'c2', 'c3', 'eta_q', 'label', 'omega', 'psi', 'rad', 'rmr0', 'th32', 'u38', 'value']
        self.available_wildcard_properties =            []
        _explicit_args = kwargs.pop('_explicit_args')
        _locals = locals()
        _locals.update(kwargs)  # For wildcard attrs
        args = {k: _locals[k] for k in _explicit_args if k != 'children'}
        for k in ['label']:
            if k not in args:
                raise TypeError(
                    'Required argument `' + k + '` was not specified.')
        super(CoastApp, self).__init__(**args)

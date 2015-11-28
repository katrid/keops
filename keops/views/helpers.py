from katrid.forms import widgets, ModelChoiceField, ModelMultipleChoiceField, GridField
from katrid.db import models


WIDGET_TYPES = {
    widgets.Input: 'text',
    widgets.Textarea: 'textarea',
    widgets.Select: 'select',
    widgets.DateInput: 'date',
}


def get_form_field(form, field):
    f = form.base_fields[field]
    attrs = f.widget_attrs(f.widget)
    db_field = form._meta.model._meta.get_field(field)
    if isinstance(f, ModelChoiceField):
        attrs['type'] = 'lookup'
        attrs['content-field'] = str(db_field).lower()
        if isinstance(f, ModelMultipleChoiceField):
            attrs['multiple'] = 'multiple'
    elif isinstance(f, GridField):
        attrs['type'] = 'grid'
    else:
        attrs['type'] = WIDGET_TYPES.get(f.widget.__class__, 'text')
    attrs['label'] = f.label
    if f.required:
        attrs['required'] = True
    if isinstance(f.widget, widgets.Select) and attrs.get('type') != 'lookup':
        attrs['choices'] = f.widget.choices
    return attrs, db_field


def get_list_field(form, field):
    f = form.base_fields[field]
    attrs = {'label': f.label}
    return attrs, form._meta.model._meta.get_field(field)

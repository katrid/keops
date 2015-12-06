from katrid.forms import widgets, ModelChoiceField, ModelMultipleChoiceField, GridField
from katrid import forms
from katrid.db import models


WIDGET_TYPES = {
    widgets.Input: 'text',
    widgets.Textarea: 'textarea',
    widgets.Select: 'select',
    widgets.DateInput: 'date',
    widgets.DateTimeInput: 'datetime',
}


FIELD_LENGTH = (
    (5, '1'),
    (10, '2'),
    (30, '3'),
    (50, '4'),
    (70, '5'),
    (80, '6'),
    (100, '12'),
)

FIELD_TYPE_LENGTH = {
    'date': '2',
    'lookup': '6',
    'decimal': '3',
    'default': '6',
    'multiple': '12',
    'grid': '12',
}

DEFAULT_TYPE_LENGTH = 6


def get_form_field(form, field):
    f = form.base_fields[field]
    attrs = f.widget_attrs(f.widget)
    db_field = form._meta.model._meta.get_field(field)
    if isinstance(f, ModelChoiceField):
        attrs['content-field'] = str(db_field).lower()
        if isinstance(f, ModelMultipleChoiceField):
            attrs['multiple'] = 'multiple'
            field_type = 'multiple'
        else:
            field_type = 'lookup'
    elif isinstance(f, GridField):
        field_type = 'grid'
    elif isinstance(db_field, models.DecimalField):
        field_type = 'decimal'
    else:
        field_type = WIDGET_TYPES.get(f.widget.__class__, 'text')
    attrs['label'] = f.label
    if f.required:
        attrs['required'] = True
    if isinstance(f.widget, widgets.Select) and field_type not in ('lookup', 'multiple', 'grid'):
        attrs['choices'] = f.widget.choices
        field_type = 'select'

    if field_type == 'text' and isinstance(db_field, models.CharField):
        maxlength = getattr(db_field, 'max_length')
        if maxlength:
            for k in FIELD_LENGTH:
                if maxlength <= k[0]:
                    attrs['cols'] = k[1]
                    break
        else:
            attrs['cols'] = DEFAULT_TYPE_LENGTH
    else:
        attrs['cols'] = FIELD_TYPE_LENGTH.get(field_type, DEFAULT_TYPE_LENGTH)

    if field_type == 'multiple':
        attrs['type'] = 'lookup'
    else:
        attrs['type'] = field_type

    return attrs, db_field


def get_list_field(form, field):
    m = form._meta.model
    f = form.base_fields.get(field, None) or getattr(form._meta.model, field)
    if field == '__str__':
        attrs = {'label': m._meta.verbose_name}
    else:
        attrs = {'label': f.label}
    if isinstance(f, forms.Field):
        return attrs, form._meta.model._meta.get_field(field)
    return attrs, f

from xml.etree import ElementTree as et
from katrid.conf import settings
from katrid.shortcuts import render
from katrid.http import Http404, HttpResponse
from katrid.utils.translation import gettext_lazy as _
from katrid.utils.text import capfirst
from katrid.db import models
from katrid.apps import apps
from katrid.template.loader import select_template
from katrid.template.context import RequestContext

from keops.forms import get_form, get_model_form
from . import helpers


def show_form(request):
    form_name = request.GET.get('form')
    form = get_form(form_name)
    if form is None:
        raise Http404()
    if request.method == 'POST':
        form = form(request.POST)
    else:
        form = form()
    return form.render(request, view=request.GET.get('view', 'form'))


def show_model(request, app_label, model_name):
    model = apps.get_model(app_label, model_name)
    mode = request.GET.get('mode', 'list')
    form = get_model_form(model, fields='__all__')
    # Find model form template
    template = select_template([
        'keops/forms/%s/%s/%s.xml' % (app_label, model_name, mode),
        'keops/forms/%s.xml' % mode,
    ])
    ctx = {
        'model': model,
        'form': form,
        'opts': model._meta,
    }
    if mode == 'list':
        xform = List(template.render(ctx))
    else:
        xform = Form(template.render(ctx))
    xform.form = form
    print(xform.render())
    return HttpResponse(xform.render())


###########################################################################
# XML Form Utils                                                          #
###########################################################################


class BaseView(object):
    def __init__(self, xml, form=None):
        self._xml = xml
        self.form = form

    def get_field_list(self):
        xml = et.fromstring(self._xml)
        return xml.iter('field')

    def render(self):
        raise NotImplementedError()

    def __str__(self):
        return self.render()


class Form(BaseView):
    _field_stack = []

    def read_node(self, el, parent_field=None):
        f = None
        attrs = None
        if el.tag == 'field' and 'name' in el.attrib:
            field = el.attrib
            #if isinstance(parent_field, models.OneToManyField):
            #    if not hasattr(parent_field, '_admin'):
            #        parent_field._admin = self.form.admin_site.get_admin(parent_field.related.related_model)
            #    #attrs, f = helpers.get_form_field(parent_field._admin, field['name'])
            #else:
            #    attrs, f = helpers.get_form_field(self.admin, field['name'])
            attrs, f = helpers.get_form_field(self.form, field['name'])
            if attrs is not None:
                if isinstance(parent_field, models.OneToManyField):
                    attrs.pop('ng-model', None)
                    field['ng-model'] = 'formset.' + field['name']

                if 'choices' in attrs:
                    choices = attrs.pop('choices')
                    for choice in choices:
                        el.append(et.fromstring('<option value="%s">%s</option>' % choice))

                for k, v in attrs.items():
                    field.setdefault(k, str(v))
            if attrs.get('type') == 'grid':
                self._grid_field(el, f, attrs)
            elif isinstance(f, models.OneToManyField):
                el.tag = 'formset'
                print(attrs)
        elif el.tag == 'label':
            el.attrib.setdefault('class', 'label')
        elif el.tag == 'remove-button':
            el.tag = 'button'
            el.attrib['class'] = 'btn btn-default pull-right btn-sm text-danger margin-right-5'
            el.attrib['type'] = 'button'
            el.attrib['ng-click'] = "form.deleteItem(form.data.%s, $index)" % parent_field.name
            el.append(et.Element('span', {'class': 'glyphicon glyphicon-trash'}))
        if f is None:
            f = parent_field
        if el.tag != 'field':
            for child in el:
                self.read_node(child, f)

    def _grid_field(self, el, field, attrs):
        # List UI
        s = ''
        list_fields = getattr(field, 'list_fields', None)
        rel = field.related
        form = get_model_form(rel.related_model, fields='__all__')
        if list_fields is None:
            list_fields = rel.related_model._meta.list_fields or list(form.base_fields.keys())
            if list_fields and rel.field.name in list_fields:
                list_fields.remove(rel.field.name)
            s = ''.join(['<field name="%s" label="%s" />\n' % (f, form.base_fields[f].label) for f in list_fields])
        g = et.fromstring('<grid content-field="%s">%s</grid>' % (str(field).lower(), s))
        for k, v in attrs.items():
            g.attrib.setdefault(k, v)
        el.append(g)

        # Form UI
        s = ''
        fields = getattr(field, 'fields', None)
        if fields is None:
            fields = rel.related_model._meta.fields or list(form.base_fields.keys())
            if fields and rel.field.name in fields:
                fields.remove(rel.field.name)
            s = ''.join(['<field name="%s" label="%s" />\n' % (f, form.base_fields[f].label) for f in list_fields])
        g = et.fromstring('<sub-form content-field="%s">%s</sub-form>' % (str(field).lower(), s))
        for k, v in attrs.items():
            g.attrib.setdefault(k, v)
        el.append(g)

    def read_subfield(self, el):
        pass

    def render(self):
        xml = et.fromstring(self._xml)
        if xml.tag == 'form':
            if 'content-object' not in xml.attrib:
                xml.attrib['content-object'] = str(self.form._meta.model._meta)
            xml.attrib.setdefault('view-title', capfirst(self.form._meta.model._meta.verbose_name_plural))
            for field in xml:
                self.read_node(field)
            return et.tostring(xml)
        else:
            raise ValueError('Invalid root element type')


class List(BaseView):
    def render(self):
        xml = et.fromstring(self._xml)
        if xml.tag == 'list':
            if 'content-object' not in xml.attrib:
                xml.attrib['content-object'] = str(self.form._meta.model._meta)
            for field in xml:
                if field.tag == 'field':
                    field = field.attrib
                    attrs, f = helpers.get_list_field(self.form, field['name'])
                    if attrs:
                        for k, v in attrs.items():
                            field.setdefault(k, v)
            return et.tostring(xml)
        else:
            raise ValueError('Invalid root element type')

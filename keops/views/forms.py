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
    kw = {'fields': '__all__'}
    if model._meta.exclude:
        kw['exclude'] = model._meta.exclude
    form = get_model_form(model, **kw)
    # Find model form template
    template_name = model._meta.form_template if mode == 'form' else model._meta.list_template
    template = select_template([
        template_name or ('keops/%s/%s/%s.xml' % (app_label, model_name, mode)),
        'keops/%s.xml' % mode,
    ])
    ctx = {
        'model': model,
        'form': form,
        'opts': model._meta,
    }
    if 'template' in request.GET:
        return HttpResponse(template.render(ctx))
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

    def read_node(self, el, parent_field=None, form=None, **kwargs):
        f = None
        attrs = None
        field = el.attrib
        if el.tag == 'field':
            if 'name' in el.attrib:
                # Check client/server field change notification
                qnm = nm = field['name']
                if 'name_prefix' in kwargs:
                    qnm = kwargs['name_prefix'] + '.' + nm
                if qnm in self.form._meta.model._meta.api_notify_fields:
                    field['ng-server-change'] = qnm
                if form and nm in form._meta.model._meta.api_notify_fields:
                    field['ng-subfield-change'] = nm
                #if isinstance(parent_field, models.OneToManyField):
                #    if not hasattr(parent_field, '_admin'):
                #        parent_field._admin = self.form.admin_site.get_admin(parent_field.related.related_model)
                #    #attrs, f = helpers.get_form_field(parent_field._admin, field['name'])
                #else:
                #    attrs, f = helpers.get_form_field(self.admin, field['name'])
                attrs, f = helpers.get_form_field(form, nm)
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

                if 'ngmodel_suffix' in kwargs and 'ng-model' not in field:
                    field['ngModel'] = kwargs['ngmodel_suffix'] + field['name']
            else:
                el.attrib.setdefault('type', 'static')
        elif el.tag == 'label':
            el.attrib.setdefault('class', 'label')
        elif el.tag == 'formset':
            if not len(el):
                return
        elif el.tag == 'remove-button':
            el.tag = 'button'
            el.attrib['class'] = 'btn btn-default pull-right btn-sm text-danger margin-right-5'
            el.attrib['type'] = 'button'
            el.attrib['ng-click'] = "form.deleteItem(form.data.%s, $index)" % parent_field.name
            el.append(et.Element('span', {'class': 'glyphicon glyphicon-trash'}))
        if f is None:
            f = parent_field
        if el.tag == 'formset' and 'name' in el.attrib:
            field = el.attrib
            f = self.form._meta.model._meta._has_field(el.attrib['name'])
            self._formset_field(el, f, attrs)
        elif el.tag != 'field':
            for child in el:
                self.read_node(child, f, form=form, **kwargs)

    def _formset_field(self, el, field, attrs):
        field_name = str(field).lower()
        rel = field.related
        form = get_model_form(rel.related_model, fields='__all__')
        el.attrib.setdefault('content-field', field_name)
        for child in el:
            self.read_node(child, form=form, ngmodel_suffix='item.')

    def _grid_field(self, el, field, attrs):
        field_name = str(field).lower()
        has_form = has_list = False
        form_node = None
        for child in el:
            if child.tag == 'list':
                has_list = True
            elif child.tag == 'form':
                has_form = True
                child.tag = 'sub-form'
            if child.tag == 'sub-form':
                has_form = True
                child.attrib.setdefault('content-field', field_name)
                form_node = child

        list_fields = getattr(field, 'list_fields', None)
        rel = field.related
        form = get_model_form(rel.related_model, fields='__all__')
        if not has_list:
            # List UI
            s = ''
            el.attrib['content-field'] = field_name
            if list_fields is None:
                list_fields = rel.related_model._meta.list_display or list(form.base_fields.keys())
                if list_fields and rel.field.name in list_fields:
                    list_fields.remove(rel.field.name)
                s = ''.join(['<field name="%s" label="%s" type="%s" />\n' % (f, form.base_fields[f].label, helpers.get_list_field(form, f)[0].get('type', 'text')) for f in list_fields])
            g = et.fromstring('<list content-field="%s">%s</list>' % (field_name, s))
            for k, v in attrs.items():
                g.attrib.setdefault(k, v)
            el.append(g)

        if not has_form:
            # Form UI
            s = ''
            fields = getattr(field, 'fields', None)
            if fields is None:
                fields = rel.related_model._meta.fields or list(form.base_fields.keys())
                if fields and rel.field.name in fields:
                    fields.remove(rel.field.name)
                s = ''.join(['<field name="%s" label="%s" />\n' % (f, form.base_fields[f].label) for f in list_fields])
            form_node = et.fromstring('<sub-form content-field="%s">%s</sub-form>' % (field_name, s))
            for k, v in attrs.items():
                form_node.attrib.setdefault(k, v)
            el.append(form_node)

        self.read_node(form_node, form=form, name_prefix=field.name)

    def read_subfield(self, el):
        pass

    def render(self):
        xml = et.fromstring(self._xml)
        if xml.tag == 'form':
            if 'content-object' not in xml.attrib:
                xml.attrib['content-object'] = str(self.form._meta.model._meta)
            xml.attrib['ng-notify-fields'] = ','.join(self.form._meta.model._meta.api_notify_fields)
            xml.attrib.setdefault('view-title', capfirst(self.form._meta.model._meta.verbose_name_plural))
            for field in xml:
                self.read_node(field, form=self.form)
            return et.tostring(xml, method='html')
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

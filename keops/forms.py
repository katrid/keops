import json
from itertools import chain
from urllib.parse import urlencode
from katrid.db import models
from katrid.forms.models import inlineformset_factory
from katrid.shortcuts import render, Http404
from katrid.conf import settings
from katrid.utils.translation import gettext as _
import katrid.forms

FORMS = {}


def get_form(form_name):
    return FORMS.get(form_name)


def register_form(form_name, form_class):
    FORMS[form_name] = form_class


def get_model_form(model, *args, **kwargs):
    if model in FORMS:
        return FORMS[model]
    elif not settings.DEBUG and not getattr(model._meta, 'auto_create_form', False):
        raise Http404()
    kwargs.setdefault('fields', '__all__')
    form = katrid.forms.modelform_factory(model, form=ModelForm, *args, **kwargs)
    register_form(model, form)
    return form


class FormMixin(object):
    def submit(self):
        pass

    def render(self, request, view='form'):
        if request.method == 'POST' or request.method == 'DELETE':
            if self.submit(request):
                pass
        return render(request, self.Meta.form_template if view == 'form' else self.Meta.list_template, {
            'form': self,
            'current_url': urlencode({'back': request.get_full_path()})
        })

    class Meta:
        form_template = 'keops/forms/form.html'
        list_template = 'keops/forms/list.html'


class ModelFormMixin(FormMixin):
    def submit(self):
        print(self._data)
        if self.is_valid():
            self.save()
            return {'success': True, 'message': _('Data successfully saved!')}
        details = str(self.errors)
        print('form is valid', self.is_valid(), details)
        return {'success': False, 'message': _('Errors found while saving data!'), 'details': details}

    def list_queryset(self, request):
        return self.Meta.model.objects.all()


class Form(katrid.forms.Form, FormMixin):
    def __init__(self, *args, **kwargs):
        self.request = kwargs.get('request')
        super(Form, self).__init__(*args, **kwargs)


class ModelForm(katrid.forms.ModelForm, ModelFormMixin):
    def __init__(self, *args, **kwargs):
        self.request = kwargs.pop('request')
        data = kwargs.get('data')
        self._data = data
        if self.request:
            pk = data.get('id', self.request.GET.get('id'))
            if pk:
                kwargs['instance'] = self._meta.model.objects.get(pk=pk)
        super(ModelForm, self).__init__(*args, **kwargs)
        self.initial.update(data)
        self.data = self.initial

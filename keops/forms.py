from urllib.parse import urlencode
from katrid.shortcuts import render
import katrid.forms

FORMS = {}


def get_form(form_name):
    return FORMS.get(form_name)


def register_form(form_name, form_class):
    FORMS[form_name] = form_class


def get_model_form(model, *args, **kwargs):
    if model in FORMS:
        return FORMS[model]
    form = katrid.forms.modelform_factory(model, form=ModelForm, *args, **kwargs)
    register_form(model, form)
    return form


class FormMixin(object):
    def submit(self, request):
        pass

    def render(self, request, view='form'):
        if request.method == 'POST' or request.method == 'DELETE':
            if self.submit(request):
                pass
        return render(request, self.Meta.form_template if view == 'form' else self.Meta.list_template, {
            'form': self,
            'current_url': urlencode({'back': request.get_full_path()})
        })

    def list_fields(self):
        return self

    def list_queryset(self):
        return self.queryset()

    def queryset(self):
        return []

    class Meta:
        form_template = 'keops/forms/form.html'
        list_template = 'keops/forms/list.html'


class ModelFormMixin(FormMixin):
    def submit(self, request):
        super(ModelFormMixin, self).submit(request)
        if request.method == 'POST':
            self.post(request)
        elif request.method == 'DELETE':
            self.delete(request)

    def delete(self, request):
        pass

    def post(self, request):
        if self.is_valid():
            self.save()
            return True

    def list_queryset(self):
        return self.Meta.model.objects.all()


class Form(katrid.forms.Form, FormMixin):
    pass


class ModelForm(katrid.forms.ModelForm, ModelFormMixin):
    pass


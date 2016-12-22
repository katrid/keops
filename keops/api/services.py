from itertools import chain
from django.core.exceptions import ObjectDoesNotExist, FieldDoesNotExist
from django.db.models import ForeignKey, ImageField
from django.template import loader
from django.http import HttpResponse, JsonResponse
from django.utils.text import capfirst
from django.apps import apps
from django.db.models.query_utils import DeferredAttribute

from keops.models.fields import OneToManyField

from .decorators import service_method


PAGE_SIZE = 100


class ViewService(object):
    name = None
    site = None

    def __init__(self, request):
        self.request = request

    @classmethod
    def init_service(cls):
        pass

    def dispatch_action(self, action_id):
        raise NotImplementedError()


class ModelService(ViewService):
    ready = False
    model = None
    group_fields = None
    writable_fields = None
    readable_fields = None
    disp_field = 'name'
    list_fields = None
    fields = None

    @classmethod
    def init_service(cls):
        if not cls.name:
            cls.name = str(cls.model._meta)
        if cls.fields:
            for f in cls.fields:
                f.model = cls.model

    def deserialize_value(self, instance, field_name, value):
        field = self.model._meta.get_field(field_name)
        if isinstance(field, ForeignKey):
            field_name = field.attname
        setattr(instance, field_name, value)

    def deserialize(self, instance, data):
        data.pop('id', None)
        for k, v in data.items():
            self.deserialize_value(instance, k, v)
        instance.full_clean()
        if instance.pk:
            instance.save(update_fields=data.keys())
        else:
            instance.save()

    def serialize_value(self, instance, field):
        try:
            v = getattr(instance, field.name)
            if isinstance(field, ImageField):
                if v:
                    return v.name
                else:
                    return
            elif isinstance(field, ForeignKey) and v:
                return [v.pk, str(v)]
        except FieldDoesNotExist:
            return getattr(instance, field.name)
        return getattr(instance, field.attname)

    def serialize(self, instance, fields=None, exclude=None):
        opts = instance._meta
        data = {}
        deferred_fields = instance.get_deferred_fields()
        for f in chain(opts.concrete_fields, opts.private_fields, opts.many_to_many):
            if f.attname in deferred_fields or isinstance(f, OneToManyField):
                continue
            if not getattr(f, 'editable', False):
                continue
            if fields and f.name not in fields:
                continue
            if exclude and f.name in exclude:
                continue
            data[f.name] = self.serialize_value(instance, f)
        data['display_name'] = str(instance)
        return data

    def get_fields_info(self, view_type):
        opts = self.model._meta
        r = {}
        for field in chain(opts.fields, opts.many_to_many, self.fields or []):
            r[field.name] = self.get_field_info(field)
        return r

    def get_field_info(self, field):
        info = {
            'help_text': field.help_text,
            'required': not field.blank,
            'readonly': not field.editable,
            'editable': field.editable,
            'type': field.get_internal_type(),
            'caption': capfirst(field.verbose_name),
            'max_length': field.max_length,
        }
        if isinstance(field, ForeignKey):
            info['model'] = str(field.related_model._meta)
        elif isinstance(field, OneToManyField):
            field = getattr(self.model, field.related_name)
            info['field'] = str(field.rel.field.name)
            info['model'] = str(field.rel.related_model._meta)
        elif field.choices:
            info['choices'] = field.choices
        return info

    def _get(self, id):
        return self.model._default_manager.get(pk=id)

    @service_method
    def get(self, id):
        return self._get(id)

    def get_names(self, queryset):
        return [self.get_name(obj) for obj in queryset]

    def get_name(self, instance):
        return [instance.pk, str(instance)]

    def _search(self, *args, **kwargs):
        return self.model.objects.filter(**kwargs)[:100]

    @service_method
    def search(self, *args, **kwargs):
        qs = self._search(*args, **kwargs)
        if self.list_fields:
            qs = qs.only(*self.list_fields)
        return qs

    @service_method
    def search_names(self, *args, **kwargs):
        qs = self._search(*args, **kwargs)
        return self.get_names(qs)

    @service_method
    def write(self, data):
        for row in data:
            pk = row.pop('id', None)
            if pk:
                obj = self._get(pk)
            else:
                obj = self.model()
            self.deserialize(obj, row)
        return True

    @service_method
    def destroy(self, ids):
        ids = [v[0] for v in self._search(id__in=ids).only('pk').values_list('pk')]
        self._search(id__in=ids).delete()
        if not ids:
            raise ObjectDoesNotExist()
        return {
            'id': ids,
        }

    @service_method
    def get_view_info(self, view_type):
        return {
            'content': self.window_view(view_type),
            'fields': self.get_fields_info(view_type),
            'view_actions': self.get_view_actions(view_type),
        }

    def get_view_actions(self, view_type):
        return []

    def window_view(self, view_type):
        templ_name = '%s.html' % view_type
        templ = loader.select_template([
            'keops/web/admin/actions/%s/%s' % (self.name, templ_name),
            'keops/web/admin/actions/%s' % templ_name,
        ], 'jinja2')
        fields = self.model._meta.fields
        if view_type == 'list':
            if self.list_fields:
                fields = {f.name: f for f in fields if f.name in self.list_fields}
                fields = [fields[f] for f in self.list_fields]
        return templ.render({
            'opts': self.model._meta,
            'fields': fields,
            'request': self.request,
        })

    @service_method
    def get_field_choices(self, field):
        field = self.model._meta.get_field(field)
        service = str(field.related_model._meta).lower()
        if service in self.site.services:
            service = self.site.services[service](self.request)
            q = self.request.GET.get('q', None)
            d = service.search_names(**{service.disp_field + '__icontains': q})
            return d

    @service_method
    def do_view_action(self, action_name, target):
        return self.dispatch_view_action(action_name, target)

    def dispatch_view_action(self, action_name, target):
        raise NotImplemented()

    def view_action(self, view_type):
        return JsonResponse({
            'model': [None, self.name],
            'action_type': 'WindowAction',
            'view_mode': 'list,form',
            'display_name': capfirst(self.model._meta.verbose_name_plural),
        })

    def dispatch_action(self, action_id):
        if action_id == 'view':
            view_type = self.request.GET.get('view_type', 'list')
            return self.view_action(view_type)

from itertools import chain
from django.core.exceptions import ObjectDoesNotExist, FieldDoesNotExist
from django.db.models import ForeignKey, ImageField

from .decorators import service_method


class ViewService(object):
    name = None

    def __init__(self, request):
        self.request = request

    @classmethod
    def init_service(cls):
        pass


class ModelService(ViewService):
    ready = False
    model = None
    group_fields = None
    writable_fields = None
    readable_fields = None

    @classmethod
    def init_service(cls):
        if not cls.name:
            cls.name = str(cls.model._meta)

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
            if isinstance(field, ImageField):
                v = getattr(instance, field.name)
                if v:
                    return v.name
                else:
                    return
        except FieldDoesNotExist:
            return getattr(instance, field.name)
        return getattr(instance, field.attname)

    def serialize(self, instance, fields=None, exclude=None):
        opts = instance._meta
        data = {}
        for f in chain(opts.concrete_fields, opts.private_fields, opts.many_to_many):
            if not getattr(f, 'editable', False):
                continue
            if fields and f.name not in fields:
                continue
            if exclude and f.name in exclude:
                continue
            data[f.name] = self.serialize_value(instance, f)
        return data

    @service_method
    def get_fields_info(self):
        pass

    @service_method
    def get_field_info(self, field):
        pass

    def _get(self, id):
        return self._search().get(pk=id)

    @service_method
    def get(self, id):
        return self._get(id)

    def get_names(self, queryset):
        return [self.get_name(obj) for obj in queryset]

    def get_name(self, instance):
        return {'id': instance.pk, 'text': str(instance)}

    def _search(self, *args, **kwargs):
        return self.model.objects.filter(**kwargs)

    @service_method
    def search(self, *args, **kwargs):
        return self._search(*args, **kwargs)

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

from django.db import models
from django.db.models import FieldDoesNotExist, ImageField

from keops import api


class BaseModel(models.Model):
    def serialize(self):
        return {f.name: self.serializable_value(f.name) for f in self.__class__._meta.fields}

    @api.method
    def get(cls, id, **kwargs):
        return {'data': cls._default_manager.get(pk=id).serialize()}

    def serializable_value(self, field_name):
        try:
            field = self._meta.get_field(field_name)
            if isinstance(field, ImageField):
                v = getattr(self, field_name)
                if v:
                    return v.name
                else:
                    return
        except FieldDoesNotExist:
            return getattr(self, field_name)
        return getattr(self, field.attname)

    def deserialize_value(self, field_name, value):
        field = self._meta.get_field(field_name)
        if isinstance(field, models.ForeignKey):
            field_name = field.attname
        setattr(self, field_name, value)

    def deserialize(self, *args, **kwargs):
        if args and isinstance(args[0], dict):
            data = args[0]
            data.update(kwargs)
        else:
            data = kwargs
        data.pop('id', None)
        for k, v in data.items():
            self.deserialize_value(k, v)
        self.full_clean()
        if self.pk:
            self.save(update_fields=data.keys())
        else:
            self.save()

    def get_name(self):
        return self.pk, str(self)

    @classmethod
    def get_names(cls, qs):
        return [obj.get_name() for obj in qs]

    @api.method
    def search_name(cls, **kwargs):
        return cls.get_names(cls._default_manager.all())

    @api.method
    def write(cls, data=None, **kwargs):
        for row in data:
            pk = row['id']
            values = row['values']
            obj = cls._default_manager.get(pk=pk)
            obj.deserialize(values)
        return {'success': True}

    @api.method
    def search(cls, where=None, **kwargs):
        if where is None:
            qs = cls._default_manager.all()
        else:
            qs = cls._default_manager.filter(**where)
        return {'data': [obj.serialize() for obj in qs]}

    @api.method
    def get_view_info(cls, view_type='form'):
        pass

    @api.method
    def get_fields_info(cls, view_type):
        pass

    class Meta:
        abstract = True

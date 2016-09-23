from django.db import models
from django.db.models import *

from keops.api import decorators as api


class DecimalField(models.DecimalField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('max_digits', 18)
        kwargs.setdefault('decimal_places', 2)
        super(DecimalField, self).__init__(*args, **kwargs)


class CharField(models.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('null', True)
        kwargs.setdefault('blank', True)
        super(CharField, self).__init__(*args, **kwargs)

    def to_python(self, value):
        if isinstance(value, models.CharField):
            return value
        if value == None:
            return ""
        else:
            return value

    def get_db_prep_value(self, value, connection, prepared=False):
        if not value:
            return None
        else:
            return value


class BaseModel(models.Model):
    def to_dict(self):
        return {f.name: self.serializable_value(f.name) for f in self.__class__._meta.fields}

    @api.method
    def search(cls, where=None):
        return [obj.to_dict() for obj in cls._default_manager.all()]

    @api.method
    def get_view_info(cls, view_type='form'):
        pass

    @api.method
    def get_fields_info(cls, view_type):
        pass

    class Meta:
        abstract = True

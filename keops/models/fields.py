from django.db import models


def _adjust_field(field, kwargs):
    kwargs.setdefault('null', True)
    kwargs.setdefault('blank', kwargs['null'])


class DecimalField(models.DecimalField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('max_digits', 19)
        kwargs.setdefault('decimal_places', 2)
        _adjust_field(self, kwargs)
        super(DecimalField, self).__init__(*args, **kwargs)


class FloatField(models.FloatField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(FloatField, self).__init__(*args, **kwargs)


class CharField(models.CharField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('max_length', 256)
        _adjust_field(self, kwargs)
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


class SlugField(models.SlugField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault('max_length', 256)
        _adjust_field(self, kwargs)
        super(SlugField, self).__init__(*args, **kwargs)


class DateField(models.DateField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(DateField, self).__init__(*args, **kwargs)


class DateTimeField(models.DateTimeField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(DateTimeField, self).__init__(*args, **kwargs)


class SmallIntegerField(models.SmallIntegerField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(SmallIntegerField, self).__init__(*args, **kwargs)


class IntegerField(models.IntegerField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(IntegerField, self).__init__(*args, **kwargs)


class BigIntegerField(models.BigIntegerField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(BigIntegerField, self).__init__(*args, **kwargs)


class ImageField(models.ImageField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(ImageField, self).__init__(*args, **kwargs)


class ForeignKey(models.ForeignKey):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(ForeignKey, self).__init__(*args, **kwargs)


class TextField(models.TextField):
    def __init__(self, *args, **kwargs):
        _adjust_field(self, kwargs)
        super(TextField, self).__init__(*args, **kwargs)


class VirtualField(object):
    def __getattr__(self, item):
        return None

    def get_internal_type(self):
        return self.__class__.__name__


class OneToManyField(VirtualField):
    def __init__(self, related_name, **kwargs):
        self.related_name = related_name
        for k, v in kwargs.items():
            setattr(self, k, v)

    def __get__(self, instance, owner):
        if instance:
            return getattr(instance, self.related_name)
        return getattr(self.model, self.related_name)

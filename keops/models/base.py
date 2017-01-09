from django.db import models
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey


class Object(models.Model):
    name = models.CharField(max_length=128, db_index=True)
    content_type = models.ForeignKey(ContentType)
    object_id = models.BigIntegerField()
    content_object = GenericForeignKey()
    can_update = models.BooleanField(default=True)

    @classmethod
    def get_object(cls, name):
        return cls._default_manager.get(name=name)

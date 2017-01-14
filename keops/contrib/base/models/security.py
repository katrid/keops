from django.conf import settings
from django.utils.translation import gettext_lazy as _

from keops import models


class Rule(models.Model):
    name = models.CharField(max_length=256, unique=True)
    model = models.CharField(max_length=128, null=False, db_index=True)
    active = models.BooleanField(verbose_name=_('Active'), db_index=True)
    domain = models.TextField(verbose_name=_('Domain'), null=False)
    group = models.ForeignKey('auth.group', verbose_name=_('Group'))

    def __str__(self):
        return self.name


def get_user():
    from keops.middleware import local_data
    return local_data.request.user


class LogModel(models.Model):
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, default=get_user)
    created_on = models.DateTimeField(auto_now_add=True)
    modified_by = models.ForeignKey(settings.AUTH_USER_MODEL)
    modified_on = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        super(LogModel, self).save(*args, **kwargs)

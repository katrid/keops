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

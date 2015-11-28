from katrid.utils.translation import gettext_lazy as _
from katrid.conf import settings
from katrid.db import models
from .module import *


class View(ModuleElement):
    TYPE = (
        ('list', 'List'),
        ('form', 'Form'),
        ('search', 'Search'),
        ('graph', 'Graph'),
        ('calendar', 'Calendar'),
        ('diagram', 'Diagram'),
        ('gantt', 'Gantt'),
        ('kanban', 'Kanban'),
        ('view', 'Custom View'),
    )
    name = models.CharField(_('name'), max_length=128, null=False, unique=True)
    content_type = models.ForeignKey(ContentType, verbose_name=_('model'))
    priority = models.SmallIntegerField(_('priority'), default=32)
    description = models.TextField(_('description'))
    view_type = models.CharField(_('type'), max_length=16, null=False, default='tree')
    definition = models.TextField(_('definition'))
    ancestor = models.ForeignKey('self', verbose_name=_('ancestor view'), on_delete=models.CASCADE)

    class Meta:
        verbose_name = _('view')
        verbose_name_plural = _('views')


class CustomView(models.Model):
    view = models.ForeignKey(View, verbose_name=_('view'), null=False, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, verbose_name=_('user'), null=False, on_delete=models.CASCADE)
    definition = models.TextField(_('definition'))


class Report(ModuleElement):
    name = models.CharField(_('name'), max_length=256, null=False, unique=True)
    description = models.CharField(_('description'), max_length=256)
    definition = models.TextField(_('definition'))

    class Meta:
        verbose_name = _('report')
        field_groups = {
            'list_fields': ('name', 'description')
        }

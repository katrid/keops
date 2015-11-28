from katrid.utils.translation import ugettext_lazy as _
from katrid.db.models import Q
from katrid.db import models
from .element import *


class ModuleCategoryManager(models.Manager):
    def get_category(self, category_name):
        """
        Get ou create a module category by name.
        """
        if category_name:
            try:
                return self.get(name=category_name)
            except:
                return self.create(name=category_name)


class ModuleCategory(Element):
    name = models.CharField(_('name'), max_length=128, null=False)
    parent = models.ForeignKey('self', verbose_name=_('parent'))
    description = models.TextField(_('description'))
    visible = models.BooleanField(_('visible'), default=True)
    sequence = models.PositiveIntegerField(_('sequence'))

    objects = ModuleCategoryManager()


class Module(Element):
    STATUS = (
        ('not installed', _('Not installed')),
        ('installed', _('Installed')),
        ('upgrade', _('To upgrade')),
        ('uninstall', _('To uninstall')),
        ('install', _('To install')),
        ('not installable', _('Not Installable')),
    )
    name = models.CharField(_('name'), max_length=64, null=False, unique=True)
    app_label = models.CharField(_('app label'), max_length=64, null=False, unique=True)
    module_name = models.CharField(_('module name'), max_length=128, unique=True)
    category = models.ForeignKey(ModuleCategory, verbose_name=_('category'), help_text=_('Module category'))
    short_description = models.CharField(_('short description'), max_length=256)
    description = models.TextField(_('description'))
    author = models.CharField(_('author'), max_length=64)
    license_type = models.CharField(_('license'), max_length=64, help_text='Commercial, BSD, GPL...')
    version = models.CharField(max_length=32, verbose_name=_('version'), help_text=_('Installed module version'))
    last_update = models.PositiveIntegerField(_('last update'))
    icon = models.CharField(_('icon'), max_length=256)
    details = models.TextField(_('details'))
    dependencies = models.TextField(_('dependencies'))
    tooltip = models.CharField(_('tooltip'), max_length=64)
    visible = models.BooleanField(_('visible'), default=True)
    contributors = models.TextField(_('contributors'))
    auto_install = models.BooleanField(_('automatic installation'))
    sequence = models.PositiveIntegerField(_('sequence'))
    status = models.CharField(_('status'), max_length=16, readonly=True, default='not installed', choices=STATUS)
    latest_version = models.CharField(_('latest version'), max_length=32, help_text=_('Latest module version'))
    website = models.URLField()

    class Meta:
        verbose_name = _('module')

        class Admin:
            list_fields = ('name', 'app_label', 'module_name', 'short_description')
            search_fields = ('name', 'app_label', 'module_name', 'short_description')

    def __str__(self):
        return '%s (%s)' % (self.app_label, self.name)


class ModuleElement(Element):
    module = models.ForeignKey(Module, verbose_name=_('module'))

    class Meta:
        pass

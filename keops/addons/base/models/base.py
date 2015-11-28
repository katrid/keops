from katrid.utils.translation import ugettext_lazy as _
from katrid.conf import settings
from katrid.contrib.contenttypes.models import ContentType
from katrid.contrib.contenttypes.fields import GenericForeignKey
import katrid.contrib.auth.signals
from .element import *
from .module import *
from .locale import *
from .auth import *
from .action import *
from .menu import *
from .ui import *
from .module import *
from .config import *
from katrid.db import models


class File(models.Model):
    """
    Manage file contents.
    This will improve performance, preventing queryset objects to select binary field value
    """
    name = models.CharField(_('name'))
    file_format = models.CharField(max_length=10, null=False)  # document file format
    body = models.BinaryField(null=False)


class CompanyModel(models.Model):
    company = models.ForeignKey(Company, visible=False)

    class Meta:
        abstract = True


class Field(Element):
    model = models.ForeignKey(ContentType, verbose_name=_('model'), null=False)
    name = models.CharField(max_length=64, null=False, unique=True, verbose_name=_('name'))
    description = models.CharField(_('description'), max_length=64)
    help_text = models.CharField(_('help text'), max_length=128)

    class Meta:
        db_table = 'base_field'
        verbose_name = _('field')
        verbose_name_plural = _('fields')


class Attachment(models.Model):
    """
    Document attachment model.
    """
    TYPE = (('file', _('File')), ('url', 'URL'))

    content_type = models.ForeignKey(ContentType)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')
    name = models.CharField(max_length=256, null=False, verbose_name=_('name'))
    file_name = models.CharField(max_length=128)
    description = models.TextField(_('description'))
    att_type = models.CharField(_('type'), max_length=8, choices=TYPE, default='file', null=False)
    data = models.BinaryField(_('body'))
    url = models.URLField('URL')
    created_on = models.DateTimeField(_('created on'), auto_now_add=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, verbose_name=_('owner'))
    size = models.PositiveIntegerField(_('size'))

    class Meta:
        db_table = 'base_attachment'
        verbose_name = _('attachment')
        verbose_name_plural = _('attachments')


class Default(models.Model):
    content_type = models.ForeignKey(ContentType, verbose_name=_('model'), on_delete=models.CASCADE)
    field = models.CharField(_('field'), max_length=64)
    value = models.TextField(_('value'))
    user = models.ForeignKey('base.User', verbose_name=_('user'), help_text=_('Leave blank for all users'))

    class Meta:
        db_table = 'base_default'
        verbose_name = _('default field value')
        verbose_name_plural = _('default field value')


class Attribute(models.Model):
    """
    Define model extension attributes.
    """
    ATT_TYPE = (
        ('text', _('Text')),
        ('date', _('Date')),
        ('time', _('Time')),
        ('datetime', _('Date/Time')),
        ('money', _('Money')),
        ('integer', _('Integer')),
        ('float', _('Float')),
        ('textarea', _('Text Area')),
        ('choice', _('Choice')),
        ('multiplechoice', _('Multiple Choices')),
        ('foreignkey', _('Foreign Key')),
        ('logical', _('Logical')),
        ('image', _('Image')),
        ('file', _('File')),
    )
    content_type = models.ForeignKey(ContentType)
    name = models.CharField(_('attribute name'), max_length=64)
    att_type = models.CharField(_('attribute type'), max_length=16, choices=ATT_TYPE)
    widget_attrs = models.TextField(_('widget attributes'))
    default_value = models.TextField(_('default value'), help_text=_('Default attribute value'))
    trigger = models.TextField(_('attribute trigger'), help_text=_('Trigger attribute code'))

    class Meta:
        db_table = 'base_attribute'


class AttributeValue(models.Model):
    """
    Define model extension attributes values.
    """
    attribute = models.ForeignKey(Attribute, null=False)
    object_id = models.PositiveIntegerField()
    text_value = models.CharField(max_length=1024)
    texta_value = models.TextField()
    logical_value = models.BooleanField()
    file_value = models.BinaryField()
    ref_value = models.PositiveIntegerField()
    int_value = models.BigIntegerField()
    decimal_value = models.MoneyField()
    float_value = models.FloatField()
    date_value = models.DateTimeField()

    class Meta:
        db_table = 'base_attribute_value'

# TODO: Build dynamic Active Data Dictionary via database
# TODO: Build dynamic Custom User Interface via database
# TODO: Build a content translation structure
# TODO: Build a module/app installer
# TODO: Implement cron jobs

from katrid.utils.translation import gettext_lazy as _
from katrid.contrib.contenttypes.models import ContentType
from katrid.db import models


class Currency(models.Model):
    name = models.CharField(_('name'), max_length=32, null=False, unique=True)
    symbol = models.CharField(_('symbol'), max_length=10, null=False)
    rounding = models.DecimalField(_('rounding'), default=0.01)
    active = models.BooleanField(_('active'), default=True)
    display_format = models.CharField(_('display format'), max_length=16)


class Language(models.Model):
    code = models.CharField(_('locale code'), max_length=5, null=False, unique=True)
    name = models.CharField(_('name'), max_length=64, null=False, unique=True)
    iso_code = models.CharField(_('ISO code'), max_length=10)
    translate = models.BooleanField(_('translate'), default=False)
    active = models.BooleanField(_('active'), default=True)

    class Meta:
        verbose_name = _('language')


class Translation(models.Model):
    """
    Translates database field value.
    """
    content_type = models.ForeignKey(ContentType)
    name = models.CharField(_('name'), max_length=64)
    language = models.ForeignKey(Language, verbose_name=_('language'))
    source = models.CharField(_('source'), max_length=1024, db_index=True)
    value = models.TextField(_('value'))

    class Meta:
        unique_together = (('content_type', 'name'))
        verbose_name = _('translation')
        verbose_name_plural = _('translations')


class Country(models.Model):
    name = models.CharField(_('name'), max_length=64, unique=True)
    code = models.CharField(_('country code'), max_length=2, help_text='The ISO country code')
    language = models.ForeignKey(Language, verbose_name=_('language'))
    phone_code = models.CharField(_('phone code'), max_length=10)

    class Meta:
        verbose_name = _('country')
        verbose_name_plural = _('countries')


class State(models.Model):
    country = models.ForeignKey(Country, verbose_name=_('country'), null=False)
    code = models.CharField(_('state code'), max_length=3, null=False, db_index=True)
    name = models.CharField(_('name'), max_length=64, null=False, db_index=True)

    class Meta:
        db_table = 'base_state'
        unique_together = (('country', 'code'), ('country', 'name'))
        verbose_name = _('state')
        ordering = ('name',)

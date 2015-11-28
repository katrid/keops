from katrid.utils.translation import gettext_lazy as _
from katrid.db import models


class Config(models.Model):
    """
    General db configuration attributes (ui visible).
    """
    update_url = models.URLField(_('update URL'), help_text=_('Vendor update URL'))
    support_url = models.URLField(_('support URL'), help_text=_('Vendor support URL'))
    log_actions = models.BooleanField(_('log actions'), help_text=_('Log all user actions'), default=False)
    log_changes = models.BooleanField(_('log changes'), _('Log all user changes'), default=False)

    class Meta:
        verbose_name = _('config')


class ConfigParameter(models.Model):
    """
    General db configuration parameters (no ui).
    """
    key = models.CharField(_('key'), max_length=256, null=False, unique=True)
    value = models.TextField(_('value'))

    class Meta:
        db_table = 'base_config_parameter'
        verbose_name = _('config')

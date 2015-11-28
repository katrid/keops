from katrid.apps import AppConfig
from katrid.utils.translation import gettext_lazy as _


class BaseConfig(AppConfig):
    name = 'base'
    verbose_name = _('Base')
    description = _('Base module required for all keops based apps.')
    category = _('System')
    version = (0, 1)
    fixtures = ['company.json.mako', 'data.json.mako', 'auth.json.mako', 'menu.xml.mako']

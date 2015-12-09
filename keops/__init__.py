from katrid.db.models import options
from .import addons


options.DEFAULT_NAMES += ('auto_create_form',)
default_app_config = 'keops.apps.KeopsConfig'

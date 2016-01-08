from katrid.conf.app_settings import *

DATABASES = {
    'default': {
        'ENGINE': 'katrid.db.backends.sqlite3',
        'NAME': 'db.sqlite3',
    }
}

AUTH_USER_MODEL = 'base.user'

INSTALLED_APPS.append('keops')

SERIALIZATION_MODULES = {
    'python': 'keops.core.serializers.python',
    'json': 'keops.core.serializers.json',
    'xml': 'keops.core.serializers.xml_serializer',
    'yaml': 'keops.core.serializers.pyyaml',
    'csv': 'keops.core.serializers.csv_serializer',
    'txt': 'keops.core.serializers.txt_serializer',
    'mako': 'keops.core.serializers.mako_serializer',
}

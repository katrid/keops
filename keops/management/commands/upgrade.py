import os
from django.conf import settings
from django.core.management.base import AppCommand, CommandError
from django.utils.translation import activate
from jinja2 import Template

from keops.core.serializers import xml_serializer


class Command(AppCommand):
    help = 'Upgrade a Keops module'

    def _load_file(self, app_config, filename):
        s = open(filename, encoding='utf-8').read()
        s = Template(s).render(settings=settings)
        activate(settings.LANGUAGE_CODE)
        xml_serializer.Deserializer(s)

    def handle_app_config(self, app_config, **options):
        """
        Perform the command's actions for app_config, an AppConfig instance
        corresponding to an application label given on the command line.
        """
        data = getattr(app_config, 'data', None)
        if data:
            for filename in data:
                filename = os.path.join(app_config.path, 'fixtures', filename)
                self._load_file(app_config, filename)

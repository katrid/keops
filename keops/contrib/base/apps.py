from django.apps import AppConfig


class BaseConfig(AppConfig):
    name = 'keops.contrib.base'
    label = 'base'
    data = ['base.xml']

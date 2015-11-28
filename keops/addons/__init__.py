import os
import sys
from importlib import import_module
from keops import settings

BASE_DIR = os.path.dirname(__file__)
sys.path.append(BASE_DIR)


def autodiscover_package(dirname, pkg=None):
    for f in os.listdir(dirname):
        if os.path.isdir(os.path.join(dirname, f)) and not f.startswith('_'):
            try:
                m = import_module(f)
                if pkg:
                    f = '%s.%s' % (pkg, f)
                settings.INSTALLED_APPS.append(f)
            except:
                pass


def setup():
    autodiscover_package(BASE_DIR)
    print(settings.INSTALLED_APPS)

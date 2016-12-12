import json
from django.http import HttpResponse
from django.views.i18n import json_catalog, _get_locale, _parse_packages, get_formats, get_javascript_catalog


def javascript_catalog(request, domain='djangojs', packages=None):
    locale = _get_locale(request)
    packages = _parse_packages(packages)
    catalog, plural = get_javascript_catalog(locale, domain, packages)
    data = {
        'catalog': catalog,
        'formats': get_formats(),
        'plural': plural,
    }
    s = """$(document).ready(function () {var js = %s;Katrid.i18n.initialize(js.plural, js.catalog, js.formats)});""" % json.dumps(data)
    return HttpResponse(s)

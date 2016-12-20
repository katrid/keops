from django.conf import settings
import django.views.static
from django.conf.urls import url
from django.views.i18n import JavaScriptCatalog, json_catalog
import keops.urls
from keops.api import site
#import keops.report_urls
# from django.contrib import admin
import testapp.api


js_info_dict = {
    'packages': ('keops',),
}

urlpatterns = [
    url(r'^jsi18n/catalog.js$', json_catalog, js_info_dict, name='javascript-catalog'),
    url(r'^jsi18n/', JavaScriptCatalog.as_view(), name='javascript-catalog'),
] + keops.urls.urlpatterns + site.get_urls()

if settings.DEBUG:
    # static files (images, css, javascript, etc.)
    urlpatterns += [
        url(r'^media/(?P<path>.*)$', django.views.static.serve, {'document_root': settings.MEDIA_ROOT})
    ]

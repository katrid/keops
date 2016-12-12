from django.conf import settings
from django.conf.urls import url
import django.views.static
from keops.api import site
import keops.views.reports


urlpatterns = [
    url(r'^web/reports/', keops.views.reports.dashboard),
    url(r'^web/reports/view/', keops.views.reports.report),
    url(r'^api/reports/choices/', keops.views.reports.choices),
    url(r'^reports/temp/(?P<path>.*)$', django.views.static.serve, {'document_root': settings.REPORT_ROOT})
]

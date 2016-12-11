from django.conf.urls import url
from keops.api import site
import keops.views.reports


urlpatterns = [
    url(r'^web/reports/', keops.views.reports.dashboard),
    url(r'^web/reports/view/', keops.views.reports.report),
    url(r'^api/reports/choices/', keops.views.reports.choices),
]

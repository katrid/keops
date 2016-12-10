from django.conf.urls import url
import keops.views.reports
import keops.views.web


urlpatterns = [
    url(r'^web/$', keops.views.web.index),

    # Report urls
    url(r'^web/reports/', keops.views.reports.dashboard),
    url(r'^web/reports/view/', keops.views.reports.report),
    url(r'^api/reports/choices/', keops.views.reports.choices),
]

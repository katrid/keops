from django.conf.urls import url
from keops.api import site
import keops.views.web


urlpatterns = [
    url(r'^web/$', keops.views.web.index),
    url(r'^web/action/(?P<service>.*)/(?P<action_id>.*)/$', keops.views.web.action),
] + site.get_urls()

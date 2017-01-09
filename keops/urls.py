from django.conf.urls import url
from keops.api import site
import keops.views.web
import keops.views.auth


urlpatterns = [
    url(r'^web/$', keops.views.web.index),
    url(r'^web/menu/(?P<current_menu>\d+)/$', keops.views.web.index),
    url(r'^web/login/$', keops.views.auth.login),
    url(r'^web/logout/$', keops.views.auth.logout),
    url(r'^web/action/(?P<service>.*)/(?P<action_id>.*)/$', keops.views.web.action),
    url(r'^web/action/(?P<action_id>\d*)/$', keops.views.web.action, {'service': None}),
] + site.get_urls()

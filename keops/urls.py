from katrid.conf import settings
from katrid.conf.urls import url

import keops.views.client
import keops.views.actions
import keops.views.forms


urlpatterns = [
    url(r'^$', keops.views.client.home),
    url(r'^client/login/$', keops.views.client.login),
    url(r'^client/menu/(?P<menu_id>.+)/$', keops.views.client.menu),
    url(r'^client/action/(?P<action_id>.+)/$', keops.views.actions.action),
    url(r'^client/form/show/(?P<form_id>.+)/$', keops.views.forms.show_form),
]

if settings.DEBUG:
    # Simplify the prototype process
    urlpatterns.append(url(r'^client/content/show/(?P<app_label>.+)/(?P<model_name>.+)/$', keops.views.forms.show_model))
    urlpatterns.append(url(r'^client/form/show/(?P<app_label>.+)/(?P<model_name>.+)/$', keops.views.forms.show_form))

from django.conf.urls import url
from keops.api import site
import keops.views.web


urlpatterns = [
    url(r'^web/$', keops.views.web.index),
]

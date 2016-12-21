from django.conf import settings
from django.utils.translation import gettext as _
from django.shortcuts import render

from keops.api import site


def index(request):
    current_menu = None
    return render(request, '/keops/web/index.html', {
        '_': _,
        'settings': settings,
        'current_menu': current_menu,
    })


def action(request, service, action_id):
    svc = site.services[service]
    return svc(request).dispatch_action(action_id)

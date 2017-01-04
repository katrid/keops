from django.conf import settings
from django.utils.translation import gettext as _
from django.shortcuts import render
from django.contrib.auth.decorators import login_required

from keops.contrib.base.models.ui import Menu

from keops.api import site


@login_required
def index(request, current_menu=None):
    menu = Menu.objects.filter(parent_id=None)
    if current_menu is None:
        current_menu = menu.first()
    else:
        current_menu = Menu.objects.get(pk=current_menu)
    return render(request, '/keops/web/index.html', {
        '_': _,
        'menu': menu,
        'settings': settings,
        'current_menu': current_menu,
    })


@login_required
def action(request, service, action_id):
    svc = site.services[service]
    return svc(request).dispatch_action(action_id)

from django.conf import settings
from django.utils.translation import gettext as _
from django.shortcuts import render, get_object_or_404
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
    if service is None:
        from keops.contrib.base.models import Action
        action = get_object_or_404(Action, pk=action_id)
        act_cls = Action.ACTIONS[action.action_type]
        action_id = get_object_or_404(act_cls, pk=action_id)
        service = str(action_id.model.model_class()._meta)
    svc = site.services[service]
    return svc(request).dispatch_action(action_id)

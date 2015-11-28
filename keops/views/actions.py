from katrid.shortcuts import render

from base.models import Action


def action(request, action_id):
    act = Action.objects.filter(pk=action_id)
    if act:
        act = act[0]
    else:
        # Permission denied
        pass

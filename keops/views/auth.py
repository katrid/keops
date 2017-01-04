from django.conf import settings
from django.utils.translation import gettext as _
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.contrib import messages
from django.contrib import auth


def login(request):
    if request.method == 'POST':
        if request.is_ajax():
            data = {}
        else:
            data = request.POST
        username = data['username']
        pwd = data['password']
        u = auth.authenticate(username=username, password=pwd)
        if u:
            auth.login(request, u)
            return HttpResponseRedirect(request.GET.get('next', '/web/'))
        messages.error(request, _('Invalid username/password!'))
    return render(request, 'keops/web/login.html', {
        'messages': messages.get_messages(request),
        'settings': settings,
        'request': request,
    })


def logout(request):
    auth.logout(request)
    return HttpResponseRedirect('/web/login/')

from katrid.shortcuts import render
from katrid.http import HttpResponseRedirect
from katrid.contrib import auth


def login(request):
    return render(request, 'apps/auth/login.html')


def logout(request):
    auth.logout(request)
    return HttpResponseRedirect('/login/')

from katrid.shortcuts import render
from katrid.contrib.auth.decorators import login_required
from base.models import Menu


@login_required
def home(request):
    return render(request, 'apps/app.html', {
        'root_menu': Menu.objects.root_menu()
    })


@login_required
def menu(request, menu_id):
    return render(request, 'apps/app.html', {
        'root_menu': Menu.objects.root_menu(),
        'menu': Menu.objects.filter(parent_id=menu_id)[:],
    })


def login(request):
    pass

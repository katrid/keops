from katrid.shortcuts import render

from base.views.decorators import staff_member_required
from base.models import Menu, Action


#@staff_member_required
def home(request):
    return render(request, 'keops/index.html', {
        'root_menu': Menu.objects.root_menu()
    })


#@staff_member_required
def menu(request, menu_id):
    return render(request, 'keops/index.html', {
        'root_menu': Menu.objects.root_menu(),
        'menu': Menu.objects.filter(parent_id=menu_id)[:],
    })


def login(request):
    pass

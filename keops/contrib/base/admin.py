from django.contrib.auth import get_user_model, models as auth

from keops.api import site, services
from . import models


class MenuService(services.ModelService):
    model = models.Menu


class WindowActionService(services.ModelService):
    model = models.WindowAction


class UserService(services.ModelService):
    list_fields = ['username', 'email', 'last_login', 'is_superuser']
    model = get_user_model()


class GroupService(services.ModelService):
    model = auth.Group


site.register_service(UserService)
site.register_service(GroupService)
site.register_service(MenuService)
site.register_service(WindowActionService)

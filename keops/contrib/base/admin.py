from django.contrib.auth import get_user_model, models as auth

from keops.api import services
from . import models


class MenuService(services.ModelService):
    model = models.Menu


class WindowActionService(services.ModelService):
    model = models.WindowAction


class UserService(services.ModelService):
    model = get_user_model()


class GroupService(services.ModelService):
    model = auth.Group

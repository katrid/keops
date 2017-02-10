from django.contrib.auth import get_user_model, models as auth

from keops.api import site, services
from . import models


class MenuService(services.ModelService):
    model = models.Menu

    def deserialize(self, instance, data):
        super(MenuService, self).deserialize(instance, data)
        groups = self.m2m.get('groups')
        if groups:
            for g in groups:
                p = instance.parent
                while p:
                    p.groups.add(g)
                    p = p.parent


class WindowActionService(services.ModelService):
    model = models.WindowAction


class UserService(services.ModelService):
    list_fields = ['username', 'email', 'last_login', 'is_superuser']
    model = get_user_model()
    title_field = 'username'


class GroupService(services.ModelService):
    model = auth.Group


class RuleService(services.ModelService):
    model = models.Rule


class ReportService(services.ModelService):
    model = models.reports.Report


class ReportActionService(services.ModelService):
    model = models.ReportAction


class ActionService(services.ModelService):
    model = models.Action


site.register_service(UserService)
site.register_service(GroupService)
site.register_service(MenuService)
site.register_service(WindowActionService)
site.register_service(RuleService)
site.register_service(ReportService)
site.register_service(ReportActionService)
site.register_service(ActionService)

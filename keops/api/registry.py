from keops.api.services import ViewService


class Site:
    def __init__(self, name=None):
        self.name = name
        self.actions = {}
        self.services = {}

    def register_action(self, action):
        self.actions[action.name] = action

    def register_service(self, service, name=None):
        if issubclass(service, ViewService):
            service.init_service()
        if name is None and hasattr(service.model, '_meta'):
            name = str(service.model._meta).lower()
        self.services[name] = service

    def get_urls(self):
        from django.conf.urls import url
        from keops.api import views

        url_patterns = [
            url(r'^api/rpc/(?P<service>.*)/(?P<method_name>.*)/$', views.rpc)
        ]

        return url_patterns

    @property
    def urls(self):
        return self.get_urls()


site = Site('admin')

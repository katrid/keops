from .decorators import service_method


class ViewService(object):
    name = None

    def __init__(self, request):
        self.request = request


class ModelService(ViewService):
    model = None
    group_fields = None
    writable_fields = None
    readable_fields = None

    def deserialize_value(self, obj, field):
        pass

    def deserialize(self, pk, data):
        pass

    def serialize_value(self, obj, field):
        pass

    def serialize(self, obj):
        pass

    @service_method
    def get_fields_info(self):
        pass

    @service_method
    def get_field_info(self, field):
        pass

    @service_method
    def get(self, *args, **kwargs):
        pass

    def get_names(self):
        pass

    def get_name(self):
        pass

    def _search(self, *args, **kwargs):
        pass

    @service_method
    def search(self, *args, **kwargs):
        pass

    @service_method
    def search_names(self, *args, **kwargs):
        pass

    @service_method
    def write(self, *args, **kwargs):
        pass

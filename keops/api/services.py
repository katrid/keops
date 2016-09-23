

class Service:
    def __init__(self, name):
        self.name = name


class ModelService(Service):
    def __init__(self, name, model):
        super(ModelService, self).__init__(name)
        self.model = model

    def __getattr__(self, item):
        attr = getattr(self.model, item)
        if attr.exposed:
            return attr

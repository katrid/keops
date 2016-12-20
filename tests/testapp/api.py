from keops.api import site
from keops.api.services import ModelService

from testapp import models


class AuthorModelService(ModelService):
    model = models.Author


class BookModelService(ModelService):
    model = models.Book


site.register_service(AuthorModelService)
site.register_service(BookModelService)

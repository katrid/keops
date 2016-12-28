from keops.api import site
from keops.api.services import ModelService
from keops.models import OneToManyField

from testapp import models


class AuthorModelService(ModelService):
    model = models.Author
    extra_fields = [models.OneToManyField('books')]


class BookModelService(ModelService):
    model = models.Book


site.register_service(AuthorModelService)
site.register_service(BookModelService)

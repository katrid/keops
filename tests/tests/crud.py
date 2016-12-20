import json
from django.test import TestCase, Client
from testapp import models


class CrudTestCase(TestCase):
    def setUp(self):
        self.connection = Client()
        models.Author.objects.create(name='Author 1')

    def test_create(self):
        models.Author.objects.create(name='Author 2')
        self.assertEqual(models.Author.objects.count(), 2)

        # Call api rpc write method
        data = [{'name': 'New Author'}]
        r = self.connection.post(
            '/api/rpc/testapp.author/write/',
            json.dumps({'kwargs': {'data': data}}),
            content_type='application/json'
        )
        author = models.Author.objects.get(name='New Author')
        self.assertIsNotNone(author)

        data = [{'name': 'New Book', 'author': author.pk}]
        r = self.connection.post(
            '/api/rpc/testapp.book/write/',
            json.dumps({'kwargs': {'data': data}}),
            content_type='application/json'
        )
        book = models.Book.objects.get(name='New Book')
        self.assertIsNotNone(book)
        self.assertEqual(book.author_id, author.pk)

    def test_read(self):
        author = models.Author.objects.first()
        self.assertEqual(author.name, 'Author 1')

        author = models.Author.objects.get(name='Author 1')
        self.assertEqual(author.name, 'Author 1')

        # Call api rpc get method
        r = self.connection.post(
            '/api/rpc/testapp.author/get/',
            json.dumps({'args': [1]}),
            content_type='application/json'
        )
        result = r.json()
        self.assertEqual(r.status_code, 200)
        self.assertEqual(result['status'], 'ok')
        self.assertTrue(result['ok'])
        self.assertEqual(result['result']['data']['name'], 'Author 1')

    def test_update(self):
        author = models.Author.objects.first()
        self.assertEqual(author.name, 'Author 1')
        author.name = 'Author 2'
        author.save()

        # Call api rpc write method
        data = [{'id': author.pk, 'name': 'New Author 2 Name'}]
        r = self.connection.put(
            '/api/rpc/testapp.author/write/',
            json.dumps({'kwargs': {'data': data}}),
            content_type='application/json'
        )
        author = models.Author.objects.get(pk=author.pk)
        self.assertIsNotNone(author)
        self.assertEqual(author.name, 'New Author 2 Name')

        data = [{'name': 'New Book', 'author': author.pk}]
        r = self.connection.post(
            '/api/rpc/testapp.book/write/',
            json.dumps({'kwargs': {'data': data}}),
            content_type='application/json'
        )
        book = models.Book.objects.get(name='New Book')
        self.assertIsNotNone(book)
        self.assertEqual(book.author_id, author.pk)

    def test_destroy(self):
        models.Author.objects.first().delete()
        self.assertEqual(models.Author.objects.count(), 0)

        author = models.Author.objects.create(name='Author 1')

        # Call api rpc destroy method
        r = self.connection.delete(
            '/api/rpc/testapp.author/destroy/',
            json.dumps({'kwargs': {'ids': [author.pk]}}),
            content_type='application/json'
        )
        data = r.json()
        self.assertEqual(r.status_code, 200)
        self.assertEqual(data['result']['id'], [author.pk])
        self.assertEqual(models.Author.objects.count(), 0)

        r = self.connection.delete(
            '/api/rpc/testapp.author/destroy/',
            json.dumps({'kwargs': {'ids': [author.pk]}}),
            content_type='application/json'
        )
        data = r.json()
        self.assertEqual(r.status_code, 404)
        self.assertEqual(data['status'], 'not found')
        self.assertFalse(data['ok'])
        self.assertTrue(data['fail'])

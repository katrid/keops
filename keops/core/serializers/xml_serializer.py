from xml.etree import ElementTree as etree
from django.utils.translation import gettext as _
from django.db import DEFAULT_DB_ALIAS
from django.core.serializers.python import Deserializer as PythonDeserializer, _get_model
from django.core.serializers import base
from django.core.exceptions import ObjectDoesNotExist
from django.contrib.contenttypes.models import ContentType

from keops.models import Object


def read_object(obj, **attrs):
    if not isinstance(obj, dict):
        values = obj.getchildren()
        obj = dict(obj.attrib)
    else:
        values = obj['children']

    if 'fields' not in obj:
        obj['fields'] = {}

    for child in values:
        if child.tag == 'field':
            if 'ref' in child.attrib:
                obj['fields'][child.attrib['name']] = Object.get_object(child.attrib['ref']).object_id
            elif 'model' in child.attrib:
                obj['fields'][child.attrib['name']] = ContentType.objects.only('pk').get_by_natural_key(*child.attrib['model'].split('.')).pk
            else:
                s = child.text
                if 'translate' in child.attrib:
                    s = _(s)
                obj['fields'][child.attrib['name']] = s

    obj_name = obj.pop('id')
    obj_id = None
    try:
        obj_id = Object.objects.get(name=obj_name)
        instance = obj_id.content_object
        for k, v in obj['fields'].items():
            setattr(instance, k, v)
        instance.save()
    except ObjectDoesNotExist:
        instance = base.build_instance(_get_model(obj['model']), obj['fields'], attrs.get('using', DEFAULT_DB_ALIAS))
        instance.save()
        ct = ContentType.objects.get_by_natural_key(instance._meta.app_label, instance._meta.model_name.lower())
        obj_id = Object.objects.create(
            name=obj_name,
            object_id=instance.pk,
            content_type=ct
        )
    return instance


def read_menu(obj, parent=None, **attrs):
    lst = []
    action_id = obj.attrib.get('action')
    url = obj.attrib.get('url')
    if action_id:
        sys_obj = Object
        try:
            action_id = sys_obj.get_object(action_id).object_id
        except ObjectDoesNotExist:
            raise Exception('The object id "%s" does not exist' % action_id)
    s = obj.attrib.get('name')
    if attrs.get('translate'):
        s = _(s)
    fields = {
        'parent_id': obj.attrib.get('parent', parent),
        'action_id': action_id,
        'name': s,
    }
    if url:
        fields['url'] =  url
    if obj.attrib.get('sequence'):
        fields['sequence'] = obj.attrib['sequence']
    menu = {
        'model': 'base.menu',
        'id': obj.attrib.get('id'),
        'fields': fields
    }
    lst.append(menu)
    menu['children'] = []
    menu = read_object(menu, **attrs)
    for child in obj:
        r = read_menu(child, parent=menu.pk, **attrs)
        lst.extend(r)
    return lst


def read_action(obj, **attrs):
    act = obj.attrib['type']
    s = obj.attrib['name']
    if obj.attrib.get('name'):
        s = _(s)
    fields = {
        'name': s,
    }
    if 'model' in obj.attrib:
        model = _get_model(obj.attrib['model'])
        fields['model'] = ContentType.objects.get_by_natural_key(model._meta.app_label, model._meta.model_name)
    action = {
        'model': act,
        'id': obj.attrib['id'],
        'children': [],
        'fields': fields,
    }
    return read_object(action, **attrs)


def read_template(obj, **attrs):
    templ = {
        'model': 'ui.view',
        'type': 'template',
        'id': obj.attrib.get('id'),
    }
    return read_object(templ)


def read_view(obj, **attrs):
    view = {
        'model': 'ui.view',
        'id': obj.attrib.get('id'),
        'type': obj.attrib.get('type', 'view'),
    }
    return read_object(view)

TAGS = {
    'object': read_object,
    'action': read_action,
    'template': read_template,
    'view': read_view,
    'menuitem': read_menu,
}


def Deserializer(stream_or_string, app_label=None, **options):
    if not isinstance(stream_or_string, (bytes, str)):
        stream_or_string = stream_or_string.read()
    if isinstance(stream_or_string, bytes):
        stream_or_string = stream_or_string.decode('utf-8')
    data = etree.fromstring(stream_or_string)
    lst = []
    trans = data.attrib.get('translate')
    for el in data:
        obj = TAGS[el.tag](el, app_label=app_label, translate=trans)
        if isinstance(obj, list):
            lst.extend(obj)
        elif obj:
            lst.append(obj)
    return lst

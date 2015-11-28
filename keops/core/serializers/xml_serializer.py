from xml.etree import ElementTree
from katrid.contrib.contenttypes.models import ContentType
from katrid.core.serializers import base, get_deserializer

from base.models import Menu, ModelData, ViewAction


class Serializer(base.Serializer):
    internal_use_only = False


def set_id(obj, id_name):
    ModelData.objects.create(name=id_name, content_object=obj)


def deserialize_menu(node, parent=None, options=None):
    """Deserialize special menu elements."""
    menu = Menu()
    menu.name = node.attrib['name']
    menu.icon = node.attrib.get('icon')
    menu.action_name = node.attrib.get('action')
    menu.sequence = node.attrib.get('sequence')
    if parent:
        menu.parent = parent
    menu.save(using=options['using'])
    if 'id' in node.attrib:
        set_id(menu, node.attrib['id'])
    return [menu] + [deserialize_menu(sub, menu, options) for sub in node]


def deserialize_action(node, options=None):
    model = node.attrib.get('model')
    view_mode = node.attrib.get('mode')
    view_types = node.attrib.get('types')
    type = node.attrib.get('type')
    if model and (not type or type == 'view'):
        model = model.rsplit('.', 1)
        model = ContentType.objects.get_by_natural_key(app_label=model[0], model=model[1])
        name = node.attrib.get('name', node.attrib.get('id'))
        act = ViewAction.objects.create(name=name, content_type=model, mode=view_mode, types=view_types)
        if 'id' in node.attrib:
            set_id(act, node.attrib['id'])
        return act


def deserialize_item(node, options=None):
    if node.tag == 'menuitem':
        return deserialize_menu(node, options=options)
    elif node.tag == 'action':
        deserialize_action(node, options)
    elif node.tag == 'record':
        fields = {}
        for f in node:
            if f.tag == 'field':
                fields[f.attrib['name']] = f.attrib['value']
        return fields


def Deserializer(stream_or_string, **options):
    """
    Deserialize a stream or string of Xml data.
    """
    doc = ElementTree.fromstring(stream_or_string)
    for el in doc:
        obj = deserialize_item(el, options)
        if obj:
            yield obj

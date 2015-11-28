import os
from katrid.utils.translation import gettext
from katrid.core.serializers.python import Serializer as PythonSerializer
from katrid.core import serializers


class Serializer(PythonSerializer):
    internal_use_only = False


def Deserializer(stream_or_string, **options):
    """
    Deserialize a stream or string of mako template data.
    """
    from mako.template import Template
    name = stream_or_string.name
    filepath = os.path.splitext(name)[0]
    # adjust filepath
    options['filepath'] = filepath
    stream_or_string = Template(stream_or_string.read()).render(_=gettext)
    return serializers.deserialize(filepath.split('.')[-1], stream_or_string, **options)

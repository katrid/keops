import os
from katrid.core.serializers.python import Serializer as PythonSerializer


class Serializer(PythonSerializer):
    """
    Convert a queryset to TXT.
    """
    internal_use_only = False

    pass


def Deserializer(stream_or_string, **options):
    """
    Deserialize a stream or string of TXT data.
    """
    def import_file(cls, filename):
        try:
            i = 0
            cols = []
            row = 0
            objects = []
            adv = False
            for line in stream_or_string.read().decode('utf-8').splitlines():
                pk = None
                row += 1
                line = line.replace(chr(9), ';').split(';')
                if i == 0:
                    cols = line
                    i += 1
                else:
                    data = line
                    kwargs = {}
                    cell = 0
                    for col in cols:
                        if cell > len(data):
                            break
                        val = data[cell].strip()

                        # Check foreign key dependency value
                        if val == '':
                            val = None
                        if '.' in col:
                            adv = True
                            val = {col[col.index('.') + 1:]: val}
                            col = col[0:col.index('.')]
                        kwargs[col] = val
                        cell += 1
                    if len(kwargs) > 0:
                        pk = kwargs.pop('pk', None)
                        obj = {'model': cls, 'fields': kwargs}
                        if pk:
                            obj['pk'] = pk
                        objects.append(obj)
            if objects:
                if adv:
                    from keops.core.serializers.python import Deserializer as PythonDeserializer
                    return PythonDeserializer(objects, **options)
                else:
                    from katrid.core.serializers.python import Deserializer as PythonDeserializer
                    return PythonDeserializer(objects, **options)
        except Exception as e:
            print('Error importing file: "%s", line: %i' % (filename, row), e)
            raise

    filepath = options.pop('filepath', stream_or_string.name)
    if filepath:
        path = filepath.split(os.path.sep)
        model = '%s.%s' % (path[-3], os.path.splitext(path[-1])[0])
        return import_file(model, filepath)

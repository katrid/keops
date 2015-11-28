import os
import csv
from django.core.serializers.python import Serializer as PythonSerializer
from django.core.serializers.python import Deserializer as PythonDeserializer


class Serializer(PythonSerializer):
    """
    Convert a queryset to CSV.
    """
    internal_use_only = False

    pass


def Deserializer(stream_or_string, **options):
    """
    Deserialize a stream or string of CSV data.
    """
    def import_file(cls, filename):
        buf = csv.reader(stream_or_string, delimiter=';', quotechar='"')
        try:
            i = 0
            cols = []
            row = 0
            obj = {'model': cls}
            for line in buf:
                row += 1
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
                        kwargs[col] = data[cell].strip()
                        cell += 1
                    if len(kwargs) > 0:
                        obj['fields'] = kwargs
                        PythonDeserializer(obj, **options)
        except Exception as e:
            print('Error importing file: "%s", line: %i' % (filename, row), e)
            raise

    filepath = options.pop('filepath')
    if filepath:
        filepath = os.path.split(filepath)
        model = '%s.%s' % (filepath[-2], os.path.splitext(filepath[-1])[-1])
        import_file(model)

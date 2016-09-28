import os
import uuid
from PIL import Image
from PIL.ExifTags import TAGS
from django.conf import settings


def process_image(file):
    temp_dir = settings.TEMP_DIR
    dest_dir = settings.MEDIA_ROOT
    rfname = os.path.join(temp_dir, str(uuid.uuid1()) + os.path.splitext(file.name)[1])
    try:
        f = open(rfname, 'wb')
        fname = str(uuid.uuid1()) + os.path.splitext(file.name)[-1].lower()
        small = '%s.small%s' % os.path.splitext(fname)
        while True:
            data = file.file.read(8192)
            f.write(data)
            if not data:
                break
        f.close()
        img = Image.open(rfname)

        img.thumbnail((500, 500))
        try:
            exif = img._getexif()
            if exif:
                exif = {TAGS.get(k): v for k, v in exif.items()}
                if 'Orientation' in exif:
                    orientation = exif['Orientation']
                    if orientation == 6:
                        img = img.rotate(-90)
                    elif orientation == 8:
                        img = img.rotate(90)
                    elif orientation == 3:
                        img = img.rotate(180)
        except:
            pass

        r = fname
        fname = os.path.join(dest_dir, fname)
        small = os.path.join(dest_dir, small)

        img.save(fname)
        img.thumbnail((120, 120))
        img.save(small)
    finally:
        os.remove(rfname)
    return r

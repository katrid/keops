import os
import uuid
from PIL import Image
from PIL.ExifTags import TAGS
from django.http import JsonResponse
from django.conf import settings


temp_dir = settings.TEMP_DIR
dest_dir = os.path.join(settings.MEDIA_ROOT, 'tmp')


def image_upload(request):
    if request.method == 'POST':
        files = request.FILES.getlist('files[]')
        r = []
        for f in files:
            r.append(process_image(f))
        if r:
            return JsonResponse({'files': r})


def process_image(file):
    rfname = os.path.join(temp_dir, str(uuid.uuid4()) + os.path.splitext(file.name)[1])
    try:
        f = open(rfname, 'wb')
        fname = str(uuid.uuid4()) + os.path.splitext(file.name)[-1].lower()
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
        img.close()
    finally:
        if os.path.isfile(rfname):
            os.unlink(rfname)
    return {
        'image': 'tmp/' + r,
        'small': 'tmp/' + os.path.basename(small),
    }


import json
from django.http import HttpResponse

from keops.utils.images import process_image


def upload(request):
    if request.method == 'POST':
        files = request.FILES.getlist('files[]')
        r = []
        for f in files:
            r.append(process_image(f))
        if r:
            return HttpResponse(json.dumps(r))
        else:
            return HttpResponse('')

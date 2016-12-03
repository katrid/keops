import json
from django.shortcuts import render
from django.http import JsonResponse

from .registry import site


def rpc(request, service, method_name):
    obj = site.services[service]
    meth = getattr(obj, method_name)
    if meth.exposed:
        if request.body:
            kwargs = json.loads(request.body.decode('utf-8'))
        else:
            kwargs = {}
        kwargs['request'] = request
        return JsonResponse({
            'result': meth(**kwargs),
        })

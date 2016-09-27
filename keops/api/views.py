from django.shortcuts import render
from django.http import JsonResponse

from .registry import site


def rpc(request, service, method_name):
    obj = site.services[service]
    meth = getattr(obj, method_name)
    if meth.exposed:
        kwargs = dict(request.POST)
        kwargs['request'] = request
        return JsonResponse({
            'result': {
                'data': meth(**kwargs),
            }
        })

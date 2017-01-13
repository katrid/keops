import json
from django.shortcuts import render
from django.conf import settings
from django.http import JsonResponse
from django.db import models
from django.core import exceptions
from django.db.utils import IntegrityError
from django.contrib.auth.decorators import login_required

from keops.api.services import ViewService, ModelService
from keops.api.registry import site


@login_required
def rpc(request, service, method_name):
    svc = site.services[service]
    if issubclass(svc, ViewService):
        svc = svc(request)
    meth = getattr(svc, method_name)
    status = 200
    if getattr(meth, 'exposed', None):
        if request.body:
            data = json.loads(request.body.decode('utf-8'))
        else:
            data = {}
        try:
            if 'args' in data:
                args = data['args']
            elif 'args' in request.GET:
                args = request.GET.getlist('args')
            else:
                args = ()
            if 'kwargs' in data:
                kwargs = data['kwargs']
            else:
                kwargs = {}
            res = meth(*args, **kwargs)
        except models.ObjectDoesNotExist as e:
            status = 404
            res = {'status': 'not found', 'ok': False, 'fail': True, 'result': None, 'message': str(e)}
        except exceptions.PermissionDenied as e:
            status = 403
            res = {'status': 'denied', 'ok': False, 'fail': True, 'result': None, 'message': str(e)}
        except exceptions.ValidationError as e:
            res = {'status': 'fail', 'ok': False, 'fail': True, 'result': None, 'messages': e.message_dict}
        except IntegrityError as e:
            res = {'status': 'fail', 'ok': False, 'fail': True, 'result': None, 'message': str(e)}
        except Exception as e:
            raise
            status = 500
            res = {'status': 'fail', 'ok': False, 'fail': True, 'result': None, 'message': str(e)}
        else:
            if isinstance(res, dict):
                if 'status' not in res and 'result' not in res:
                    res = {'status': 'ok', 'ok': True, 'result': res}
            elif isinstance(res, models.Model) and isinstance(svc, ModelService):
                res = {
                    'status': 'ok',
                    'ok': True,
                    'result': {
                        'data': [svc.serialize(res, view_type='form')],
                    }
                }
            elif isinstance(res, models.QuerySet) and isinstance(svc, ModelService):
                res = {
                    'status': 'ok',
                    'ok': True,
                    'result': {
                        'data': [svc.serialize(obj, view_type='search') for obj in res],
                        'count': getattr(res, '_count', None),
                    }
                }
            else:
                res = {'result': res, 'status': 'ok', 'ok': True}
        return JsonResponse(res, status=status)

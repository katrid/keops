from django.http import JsonResponse
from django.contrib import messages

from sopando.views.decorators import no_cache


@no_cache
def push_messages(request):
    msgs = []
    for msg in messages.get_messages(request):
        msgs.append({'type': 'danger' if msg.tags == 'error' else msg.tags, 'msg': str(msg)})
    return JsonResponse({'result': msgs, 'success': True, 'status': 'success'})

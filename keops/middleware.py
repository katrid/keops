from threading import local


local_data = local()


class LocalRequestMiddleware(object):
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        local_data.request = request
        res = self.get_response(request)
        del local_data.request
        return res

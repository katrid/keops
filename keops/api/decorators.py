
def method(fn):
    fn.exposed = True
    fn = classmethod(fn)
    fn.exposed = True
    return fn


def service_method(fn):
    fn.exposed = True
    return fn

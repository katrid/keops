
def method(fn):
    fn.exposed = True
    fn = classmethod(fn)
    fn.exposed = True
    return fn


def service_method(fn):
    fn.exposed = True
    return fn


def depends(fields):
    def wrapped(fn):
        fn = service_method(fn)
        fn.depends = fields
    return wrapped


def on_change(fields):
    def wrapped(fn):
        fn.fields = fields
    return wrapped

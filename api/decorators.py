
def method(fn):
    fn.exposed = True
    fn = classmethod(fn)
    fn.exposed = True
    return fn

from katrid.db.models import Manager


class _Manager(object):
    def submit(self, request):
        # Write submitted data using Katrid Form
        from keops.views.forms import get_model_form
        form = get_model_form(self.model)
        return form(request=request, data=request.json).submit()


Manager.submit = _Manager.submit

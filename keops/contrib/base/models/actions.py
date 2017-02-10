from django.contrib.contenttypes.models import ContentType
from django.template import loader
from django.utils.translation import gettext as _
from django.http import JsonResponse

from keops import models
from keops.api import site
from keops.models import reports


class Action(models.Model):
    ACTIONS = {}
    name = models.CharField(max_length=256, null=False)
    action_type = models.CharField(max_length=16, null=False, editable=False)
    usage = models.TextField()
    help = models.TextField()

    def get_absolute_url(self):
        return '#/action/%s/' % self.pk

    def __str__(self):
        return self.name


class WindowAction(Action):
    domain = models.TextField()
    context = models.TextField()
    object_id = models.BigIntegerField()
    model = models.ForeignKey(ContentType, related_name='+')
    source_model = models.ForeignKey(ContentType, related_name='+')
    target = models.CharField(max_length=16, choices=(('current', 'Current Window'), ('new', 'New')), default='current')
    view_mode = models.CharField(max_length=128, default='list,form')
    view_type = models.CharField(max_length=16, choices=(('list', 'List'), ('form', 'Form')), default='form', null=False)
    limit = models.PositiveIntegerField(default=100)
    filter = models.BooleanField(default=False)
    auto_search = models.BooleanField(default=True)

    class Meta:
        db_table = 'base_window_action'

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        self.action_type = 'window'
        super(WindowAction, self).save(*args, **kwargs)

    def dispatch_action(self, request):
        service = str(self.model.model_class()._meta)
        svc = site.services[service](request)
        view_type = request.GET.get('view_type', 'list')
        return svc.view_action(view_type)


class ReportAction(Action):
    report = models.ForeignKey(reports.Report, null=False)

    def save(self, *args, **kwargs):
        self.action_type = 'report'
        super(ReportAction, self).save(*args, **kwargs)

    def dispatch_action(self, request):
        ctx = {
            'request': request,
            '_': _,
        }
        return JsonResponse({
            'action_type': 'ReportAction',
            'content': loader.render_to_string(
                'keops/web/admin/actions/report.html',
                context=ctx,
                using='jinja2',
                request=request
            ),
        })


Action.ACTIONS['window'] = WindowAction
Action.ACTIONS['report'] = ReportAction

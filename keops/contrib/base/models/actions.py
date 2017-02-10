from django.contrib.contenttypes.models import ContentType

from keops import models
from keops.models import reports


class Action(models.Model):
    ACTIONS = {}
    name = models.CharField(max_length=256, null=False)
    action_type = models.CharField(max_length=16, null=False)
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

    def dispatch_action(self, service):
        view_type = service.request.GET.get('view_type', 'list')
        return service.view_action(view_type)


class ReportAction(Action):
    report = models.ForeignKey(reports.Report, null=False)

    def save(self, *args, **kwargs):
        self.action_type = 'report'
        super(ReportAction, self).save(*args, **kwargs)


Action.ACTIONS['window'] = WindowAction
Action.ACTIONS['report'] = ReportAction

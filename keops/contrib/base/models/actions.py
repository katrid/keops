from keops import models


class Action(models.Model):
    name = models.CharField(max_length=256, null=False)
    action_type = models.CharField(max_length=16, null=False)
    usage = models.TextField()
    help = models.TextField()


class WindowAction(Action):
    domain = models.TextField()
    context = models.TextField()
    object_id = models.BigIntegerField()
    model = models.ForeignKey('basemodel', related_name='+')
    source_model = models.ForeignKey('basemodel', related_name='+')
    target = models.CharField(max_length=16, choices=(('current', 'Current Window'), ('new', 'New')), default='current')
    view_mode = models.CharField(max_length=128, default='list,form')
    view_type = models.CharField(max_length=16, choices=(('list', 'List'), ('form', 'Form')), default='form', null=False)
    limit = models.PositiveIntegerField(default=100)
    filter = models.BooleanField(default=False)
    auto_search = models.BooleanField(default=True)

    class Meta:
        db_table = 'base_window_action'

import json
from katrid.utils.translation import gettext_lazy as _
from katrid.db import models
from .module import *
from .ui import *


class ActionManager(ElementManager):
    def get_by_model_name(self, model):
        model = model.rsplit('.', 1)
        ct = ContentType.objects.get(app_label=model[0], model=model[1])
        try:
            return ViewAction.objects.get(content_type=ct)
        except:
            return


class Action(ModuleElement):
    action_types = {}
    name = models.CharField(_('name'), max_length=128, null=False, unique=True)
    short_description = models.CharField(_('short description'), max_length=32)
    description = models.CharField(_('description'), max_length=256)
    action_type = models.CharField(_('type'), max_length=32, null=False, readonly=True)
    context = models.TextField(_('context'))

    objects = ActionManager()

    class Meta:
        verbose_name = _('action')
        verbose_name_plural = _('actions')
        field_groups = {
            'list_fields': ('name', 'short_description', 'description', 'action_type')
        }

    def __str__(self):
        return '%s (%s)' % (self.name, self.action_type)

    def get_absolute_url(self):
        return 'action/%i/' % self.pk

    def get_action_type(self):
        return None

    def get_context(self):
        if self.context:
            return json.dumps(self.context)
        else:
            return {}

    def save(self, *args, **kwargs):
        self.action_type = self.get_action_type()
        super(Action, self).save(*args, **kwargs)

    def execute(self, request, *args, **kwargs):
        return self.action_types[self.action_type].objects.get(pk=self.pk).execute(request, *args, **kwargs)


class URLAction(Action):
    url = models.URLField('URL', help_text=_('target URL'))
    target = models.CharField(_('target'), max_length=32)

    class Meta:
        db_table = 'base_url_action'
        verbose_name = _('URL action')
        verbose_name_plural = _('URL actions')

    def get_action_type(self):
        return 'url'


class ViewAction(Action):
    TARGET = (
        ('window', _('Current Window')),
        ('dialog', _('Dialog')),
        ('new', _('New Window')),
        ('popup', _('Browser Popup')),
    )
    VIEW_TYPE = (
        ('form', 'Form'),
        ('list', 'List'),
        ('chart', 'Chart'),
        ('calendar', 'Calendar'),
        ('kanban', 'Kanban'),
    )
    VIEW_STATE = (
        ('read', _('Read')),
        ('write', _('Write')),
        ('create', _('Create')),
        ('delete', _('Delete')),
    )
    view = models.ForeignKey(View, verbose_name=_('view'), fieldset=_('form'), help_text=_('View to show'))
    content_type = models.ForeignKey(ContentType, verbose_name=_('model'), fieldset=_('form'),
                              help_text=_('Model to show'))
    target = models.CharField(_('target'), max_length=16, choices=TARGET, fieldset=_('form'))
    mode = models.CharField(_('initial view'), max_length=16, choices=VIEW_TYPE, default='list',
                                 fieldset=_('form'))
    types = models.CharField(_('view types'), max_length=64)
    state = models.CharField(_('state'), max_length=16)

    def get_action_type(self):
        return 'form'

    class Meta:
        db_table = 'base_view_action'
        verbose_name = _('form action')
        verbose_name_plural = _('form actions')
        field_groups = {
            'list_fields': ('name', 'short_description', 'description', 'view', 'model')
        }

    def execute(self, request, *args, **kwargs):
        from .views import actions
        return actions.response_form(request, self, *args, **kwargs)


class ReportAction(Action):
    report = models.ForeignKey(Report, verbose_name=_('report'))

    def save(self, *args, **kwargs):
        if self.dialog is None:
            self.dialog = True
        super(ReportAction, self).save(*args, **kwargs)

    class Meta:
        db_table = 'base_report_action'
        verbose_name = _('report action')
        verbose_name_plural = _('report actions')

    def get_action_type(self):
        return 'report'

    def execute(self, request, *args, **kwargs):
        from katrid.http import HttpResponseRedirect
        return HttpResponseRedirect('/report/form/?id=%i' % self.report_id)

# Register form action types
Action.action_types['view'] = ViewAction
Action.action_types['url'] = URLAction
Action.action_types['report'] = ReportAction

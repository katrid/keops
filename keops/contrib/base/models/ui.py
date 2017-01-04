from keops import models


class Menu(models.Model):
    parent = models.ForeignKey('self', related_name='children')
    name = models.CharField(max_length=128, null=False)
    active = models.BooleanField(default=True)
    sequence = models.IntegerField(default=100)
    groups = models.ManyToManyField('auth.Group')
    icon = models.CharField(max_length=256)
    url = models.CharField(max_length=512)

    class Meta:
        ordering = ('parent_id', 'id')

    def get_absolute_url(self):
        return self.url or 'javascript:void(0)'

    def __str__(self):
        return self._get_full_name()

    def _get_full_name(self):
        if self.parent:
            return '%s/%s' % (self.parent, self.name)
        return self.name

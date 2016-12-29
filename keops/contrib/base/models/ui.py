from keops import models


class Menu(models.Model):
    parent = models.ForeignKey('self')
    name = models.CharField(max_length=128, null=False)
    active = models.BooleanField(default=True)
    sequence = models.IntegerField(default=100)
    groups = models.ManyToManyField('auth.Group')
    icon = models.CharField(max_length=256)



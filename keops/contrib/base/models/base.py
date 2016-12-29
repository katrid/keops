from keops import models


class BaseModel(models.Model):
    name = models.CharField(max_length=128, null=False)
    app_label = models.CharField(max_length=64)

    class Meta:
        db_table = 'base_table'

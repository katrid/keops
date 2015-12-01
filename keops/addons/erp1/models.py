from katrid.db import models


class Cidade(models.Model):
    nome = models.CharField(max_length=32)

    class Meta:
        search_fields = ['nome__startswith']

    def __str__(self):
        return self.nome


class Produto(models.Model):
    nome = models.CharField(max_length=100)

    class Meta:
        search_fields = ['nome__icontains']

    def __str__(self):
        return self.nome


class Cliente(models.Model):
    nome = models.CharField(max_length=100, blank=False)
    sexo = models.CharField(max_length=16, blank=False, choices=(
        ('M', 'Masculino'),
        ('F', 'Feminino'),
    ))
    data_nascimento = models.DateField('Data Nascimento')
    cidade = models.ForeignKey(Cidade)

    revendas = models.ManyToManyField(Produto)
    compras = models.OneToManyField('clienteproduto_set')

    class Meta:
        list_fields = ['nome', 'cidade']

    def __str__(self):
        return self.nome


class ClienteProduto(models.Model):
    produto = models.ForeignKey(Produto)
    cliente = models.ForeignKey(Cliente)
    date_time = models.DateTimeField()

    def __str__(self):
        return '%s - %s' % (str(self.cliente), str(self.produto))

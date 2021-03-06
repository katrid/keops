# -*- coding: utf-8 -*-
# Generated by Django 1.10.3 on 2017-04-19 03:16
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion
import keops.models.fields


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('contenttypes', '0002_remove_content_type_name'),
    ]

    operations = [
        migrations.CreateModel(
            name='Report',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', keops.models.fields.CharField(blank=True, max_length=256, null=True)),
            ],
            options={
                'db_table': 'keops_report',
            },
        ),
        migrations.CreateModel(
            name='UserReport',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', keops.models.fields.CharField(blank=True, max_length=256, null=True)),
                ('empresa_id', keops.models.fields.IntegerField(blank=True, null=True)),
                ('user_id', keops.models.fields.IntegerField(blank=True, null=True)),
                ('user_params', keops.models.fields.TextField(blank=True, null=True)),
            ],
            options={
                'db_table': 'keops_user_report',
            },
        ),
        migrations.CreateModel(
            name='Object',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(db_index=True, max_length=128)),
                ('object_id', models.BigIntegerField()),
                ('can_update', models.BooleanField(default=True)),
                ('content_type', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='contenttypes.ContentType')),
            ],
        ),
    ]

# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import katrid.contrib.auth.models
import katrid.core.validators
from katrid.db import migrations, models
import katrid.db.models.deletion
import katrid.utils.timezone


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('auth', '0007_alter_validators_add_error_messages'),
        ('contenttypes', '0002_remove_content_type_name'),
    ]

    operations = [
        migrations.CreateModel(
            name='User',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('password', models.CharField(blank=True, max_length=128, null=True, verbose_name='password')),
                ('last_login', models.DateTimeField(blank=True, null=True, verbose_name='last login')),
                ('is_superuser', models.BooleanField(default=False, help_text='Designates that this user has all permissions without explicitly assigning them.', verbose_name='superuser status')),
                ('username', models.CharField(blank=True, error_messages={'unique': 'A user with that username already exists.'}, help_text='Required. 30 characters or fewer. Letters, digits and @/./+/-/_ only.', max_length=30, null=True, unique=True, validators=[katrid.core.validators.RegexValidator('^[\\w.@+-]+$', 'Enter a valid username. This value may contain only letters, numbers and @/./+/-/_ characters.')], verbose_name='username')),
                ('first_name', models.CharField(blank=True, max_length=30, null=True, verbose_name='first name')),
                ('last_name', models.CharField(blank=True, max_length=30, null=True, verbose_name='last name')),
                ('email', models.EmailField(blank=True, max_length=254, null=True, verbose_name='email address')),
                ('is_staff', models.BooleanField(default=False, help_text='Designates whether the user can log into this admin site.', verbose_name='staff status')),
                ('is_active', models.BooleanField(default=True, help_text='Designates whether this user should be treated as active. Unselect this instead of deleting accounts.', verbose_name='active')),
                ('date_joined', models.DateTimeField(blank=True, default=katrid.utils.timezone.now, null=True, verbose_name='date joined')),
                ('email_signature', models.TextField(blank=True, null=True, verbose_name='e-mail signature')),
                ('document_signature', models.TextField(blank=True, null=True, verbose_name='document signature')),
                ('status', models.CharField(blank=True, choices=[('created', 'Created'), ('activated', 'activated')], max_length=16, null=True)),
            ],
            options={
                'db_table': 'auth_user',
            },
            managers=[
                ('objects', katrid.contrib.auth.models.UserManager()),
            ],
        ),
        migrations.CreateModel(
            name='Attachment',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('object_id', models.PositiveIntegerField(blank=True, null=True)),
                ('name', models.CharField(blank=True, max_length=256, null=True, verbose_name='name')),
                ('file_name', models.CharField(blank=True, max_length=128, null=True)),
                ('description', models.TextField(blank=True, null=True, verbose_name='description')),
                ('att_type', models.CharField(blank=True, choices=[('file', 'File'), ('url', 'URL')], default='file', max_length=8, null=True, verbose_name='type')),
                ('data', models.BinaryField(blank=True, null=True, verbose_name='body')),
                ('url', models.URLField(blank=True, null=True, verbose_name='URL')),
                ('created_on', models.DateTimeField(auto_now_add=True, null=True, verbose_name='created on')),
                ('size', models.PositiveIntegerField(blank=True, null=True, verbose_name='size')),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType')),
                ('owner', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.User', verbose_name='owner')),
            ],
            options={
                'verbose_name': 'attachment',
                'verbose_name_plural': 'attachments',
                'db_table': 'base_attachment',
            },
        ),
        migrations.CreateModel(
            name='Attribute',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=64, null=True, verbose_name='attribute name')),
                ('att_type', models.CharField(blank=True, choices=[('text', 'Text'), ('date', 'Date'), ('time', 'Time'), ('datetime', 'Date/Time'), ('money', 'Money'), ('integer', 'Integer'), ('float', 'Float'), ('textarea', 'Text Area'), ('choice', 'Choice'), ('multiplechoice', 'Multiple Choices'), ('foreignkey', 'Foreign Key'), ('logical', 'Logical'), ('image', 'Image'), ('file', 'File')], max_length=16, null=True, verbose_name='attribute type')),
                ('widget_attrs', models.TextField(blank=True, null=True, verbose_name='widget attributes')),
                ('default_value', models.TextField(blank=True, help_text='Default attribute value', null=True, verbose_name='default value')),
                ('trigger', models.TextField(blank=True, help_text='Trigger attribute code', null=True, verbose_name='attribute trigger')),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType')),
            ],
            options={
                'db_table': 'base_attribute',
            },
        ),
        migrations.CreateModel(
            name='AttributeValue',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('object_id', models.PositiveIntegerField(blank=True, null=True)),
                ('text_value', models.CharField(blank=True, max_length=1024, null=True)),
                ('texta_value', models.TextField(blank=True, null=True)),
                ('logical_value', models.BooleanField()),
                ('file_value', models.BinaryField(blank=True, null=True)),
                ('ref_value', models.PositiveIntegerField(blank=True, null=True)),
                ('int_value', models.BigIntegerField(blank=True, null=True)),
                ('decimal_value', models.MoneyField(blank=True, decimal_places=2, default=0, max_digits=18, null=True)),
                ('float_value', models.FloatField(blank=True, null=True)),
                ('date_value', models.DateTimeField(blank=True, null=True)),
                ('attribute', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Attribute')),
            ],
            options={
                'db_table': 'base_attribute_value',
            },
        ),
        migrations.CreateModel(
            name='Category',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, help_text='Category name', max_length=64, null=True, verbose_name='name')),
                ('active', models.BooleanField(default=True, verbose_name='active')),
                ('parent', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Category', verbose_name='parent category')),
            ],
            options={
                'verbose_name': 'Contact Category',
                'verbose_name_plural': 'Contact Categories',
                'db_table': 'base_contact_category',
            },
        ),
        migrations.CreateModel(
            name='Company',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=100, null=True, verbose_name='name')),
                ('logo', models.ImageField(blank=True, null=True, upload_to='', verbose_name='logo')),
                ('report_style', models.CharField(blank=True, max_length=64, null=True, verbose_name='report style')),
                ('report_header', models.TextField(blank=True, null=True, verbose_name='report header')),
                ('report_footer', models.TextField(blank=True, null=True, verbose_name='report footer')),
            ],
            options={
                'verbose_name': 'company',
                'verbose_name_plural': 'companies',
                'db_table': 'base_company',
            },
        ),
        migrations.CreateModel(
            name='Config',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('update_url', models.URLField(blank=True, help_text='Vendor update URL', null=True, verbose_name='update URL')),
                ('support_url', models.URLField(blank=True, help_text='Vendor support URL', null=True, verbose_name='support URL')),
                ('log_actions', models.BooleanField(default=False, help_text='Log all user actions', verbose_name='log actions')),
                ('Log all user changes', models.BooleanField(default=False, verbose_name='log changes')),
            ],
            options={
                'verbose_name': 'config',
            },
        ),
        migrations.CreateModel(
            name='ConfigParameter',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('key', models.CharField(blank=True, max_length=256, null=True, unique=True, verbose_name='key')),
                ('value', models.TextField(blank=True, null=True, verbose_name='value')),
            ],
            options={
                'verbose_name': 'config',
                'db_table': 'base_config_parameter',
            },
        ),
        migrations.CreateModel(
            name='Contact',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=128, null=True, verbose_name='name')),
                ('image', models.ImageField(blank=True, null=True, upload_to='', verbose_name='image')),
                ('active', models.BooleanField(default=True, verbose_name='active')),
                ('time_zone', models.CharField(blank=True, max_length=32, null=True, verbose_name='time zone')),
                ('comments', models.TextField(blank=True, null=True, verbose_name='comments')),
                ('address', models.CharField(blank=True, max_length=256, null=True, verbose_name='address')),
                ('city', models.CharField(blank=True, max_length=64, null=True, verbose_name='city')),
                ('zip_code', models.CharField(blank=True, max_length=32, null=True, verbose_name='zip')),
                ('email', models.EmailField(blank=True, max_length=254, null=True, unique=True, verbose_name='email')),
                ('website', models.URLField(blank=True, null=True, verbose_name='website')),
                ('phone', models.CharField(blank=True, max_length=64, null=True, verbose_name='phone')),
                ('fax', models.CharField(blank=True, max_length=64, null=True, verbose_name='fax')),
                ('mobile', models.CharField(blank=True, max_length=64, null=True, verbose_name='mobile')),
                ('birthdate', models.DateField(blank=True, null=True, verbose_name='birthdate')),
                ('use_company_address', models.BooleanField(default=False, verbose_name='use company address')),
                ('is_company', models.BooleanField(db_index=True, default=False)),
                ('is_employee', models.BooleanField(db_index=True, default=False)),
                ('is_supplier', models.BooleanField(db_index=True, default=False)),
                ('category', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Category', verbose_name='Contact Category')),
                ('company', models.ForeignKey(blank=True, default=False, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Company')),
            ],
            options={
                'verbose_name': 'contact',
                'db_table': 'base_contact',
            },
        ),
        migrations.CreateModel(
            name='Country',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=64, null=True, unique=True, verbose_name='name')),
                ('code', models.CharField(blank=True, help_text='The ISO country code', max_length=2, null=True, verbose_name='country code')),
                ('phone_code', models.CharField(blank=True, max_length=10, null=True, verbose_name='phone code')),
            ],
            options={
                'verbose_name': 'country',
                'verbose_name_plural': 'countries',
            },
        ),
        migrations.CreateModel(
            name='Currency',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=32, null=True, unique=True, verbose_name='name')),
                ('symbol', models.CharField(blank=True, max_length=10, null=True, verbose_name='symbol')),
                ('rounding', models.DecimalField(blank=True, decimal_places=2, default=0.01, max_digits=18, null=True, verbose_name='rounding')),
                ('active', models.BooleanField(default=True, verbose_name='active')),
                ('display_format', models.CharField(blank=True, max_length=16, null=True, verbose_name='display format')),
            ],
        ),
        migrations.CreateModel(
            name='CustomView',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('definition', models.TextField(blank=True, null=True, verbose_name='definition')),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.User', verbose_name='user')),
            ],
        ),
        migrations.CreateModel(
            name='Default',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('field', models.CharField(blank=True, max_length=64, null=True, verbose_name='field')),
                ('value', models.TextField(blank=True, null=True, verbose_name='value')),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType', verbose_name='model')),
                ('user', models.ForeignKey(blank=True, help_text='Leave blank for all users', null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.User', verbose_name='user')),
            ],
            options={
                'verbose_name': 'default field value',
                'verbose_name_plural': 'default field value',
                'db_table': 'base_default',
            },
        ),
        migrations.CreateModel(
            name='Element',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ],
        ),
        migrations.CreateModel(
            name='File',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=64, null=True, verbose_name='name')),
                ('file_format', models.CharField(blank=True, max_length=10, null=True)),
                ('body', models.BinaryField(blank=True, null=True)),
            ],
        ),
        migrations.CreateModel(
            name='Group',
            fields=[
                ('group_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='auth.Group')),
            ],
            bases=('auth.group',),
        ),
        migrations.CreateModel(
            name='Language',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(blank=True, max_length=5, null=True, unique=True, verbose_name='locale code')),
                ('name', models.CharField(blank=True, max_length=64, null=True, unique=True, verbose_name='name')),
                ('iso_code', models.CharField(blank=True, max_length=10, null=True, verbose_name='ISO code')),
                ('translate', models.BooleanField(default=False, verbose_name='translate')),
                ('active', models.BooleanField(default=True, verbose_name='active')),
            ],
            options={
                'verbose_name': 'language',
            },
        ),
        migrations.CreateModel(
            name='ModelData',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, db_index=True, max_length=128, null=True)),
                ('object_id', models.PositiveIntegerField(blank=True, null=True)),
                ('can_change', models.BooleanField(default=True)),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType')),
            ],
        ),
        migrations.CreateModel(
            name='State',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(blank=True, db_index=True, max_length=3, null=True, verbose_name='state code')),
                ('name', models.CharField(blank=True, db_index=True, max_length=64, null=True, verbose_name='name')),
                ('country', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Country', verbose_name='country')),
            ],
            options={
                'ordering': ('name',),
                'verbose_name': 'state',
                'db_table': 'base_state',
            },
        ),
        migrations.CreateModel(
            name='Translation',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=64, null=True, verbose_name='name')),
                ('source', models.CharField(blank=True, db_index=True, max_length=1024, null=True, verbose_name='source')),
                ('value', models.TextField(blank=True, null=True, verbose_name='value')),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType')),
                ('language', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Language', verbose_name='language')),
            ],
            options={
                'verbose_name': 'translation',
                'verbose_name_plural': 'translations',
            },
        ),
        migrations.CreateModel(
            name='UserData',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('key', models.CharField(blank=True, db_index=True, max_length=64, null=True)),
                ('value', models.TextField(blank=True, null=True)),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.User')),
            ],
            options={
                'db_table': 'auth_user_data',
            },
        ),
        migrations.CreateModel(
            name='Field',
            fields=[
                ('element_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Element')),
                ('name', models.CharField(blank=True, max_length=64, null=True, unique=True, verbose_name='name')),
                ('description', models.CharField(blank=True, max_length=64, null=True, verbose_name='description')),
                ('help_text', models.CharField(blank=True, max_length=128, null=True, verbose_name='help text')),
                ('model', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType', verbose_name='model')),
            ],
            options={
                'verbose_name': 'field',
                'verbose_name_plural': 'fields',
                'db_table': 'base_field',
            },
            bases=('base.element',),
        ),
        migrations.CreateModel(
            name='Module',
            fields=[
                ('element_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Element')),
                ('name', models.CharField(blank=True, max_length=64, null=True, unique=True, verbose_name='name')),
                ('app_label', models.CharField(blank=True, max_length=64, null=True, unique=True, verbose_name='app label')),
                ('module_name', models.CharField(blank=True, max_length=128, null=True, unique=True, verbose_name='module name')),
                ('short_description', models.CharField(blank=True, max_length=256, null=True, verbose_name='short description')),
                ('description', models.TextField(blank=True, null=True, verbose_name='description')),
                ('author', models.CharField(blank=True, max_length=64, null=True, verbose_name='author')),
                ('license_type', models.CharField(blank=True, help_text='Commercial, BSD, GPL...', max_length=64, null=True, verbose_name='license')),
                ('version', models.CharField(blank=True, help_text='Installed module version', max_length=32, null=True, verbose_name='version')),
                ('last_update', models.PositiveIntegerField(blank=True, null=True, verbose_name='last update')),
                ('icon', models.CharField(blank=True, max_length=256, null=True, verbose_name='icon')),
                ('details', models.TextField(blank=True, null=True, verbose_name='details')),
                ('dependencies', models.TextField(blank=True, null=True, verbose_name='dependencies')),
                ('tooltip', models.CharField(blank=True, max_length=64, null=True, verbose_name='tooltip')),
                ('visible', models.BooleanField(default=True, verbose_name='visible')),
                ('contributors', models.TextField(blank=True, null=True, verbose_name='contributors')),
                ('auto_install', models.BooleanField(verbose_name='automatic installation')),
                ('sequence', models.PositiveIntegerField(blank=True, null=True, verbose_name='sequence')),
                ('status', models.CharField(blank=True, choices=[('not installed', 'Not installed'), ('installed', 'Installed'), ('upgrade', 'To upgrade'), ('uninstall', 'To uninstall'), ('install', 'To install'), ('not installable', 'Not Installable')], default='not installed', max_length=16, null=True, verbose_name='status')),
                ('latest_version', models.CharField(blank=True, help_text='Latest module version', max_length=32, null=True, verbose_name='latest version')),
                ('website', models.URLField(blank=True, null=True)),
            ],
            options={
                'verbose_name': 'module',
            },
            bases=('base.element',),
        ),
        migrations.CreateModel(
            name='ModuleCategory',
            fields=[
                ('element_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Element')),
                ('name', models.CharField(blank=True, max_length=128, null=True, verbose_name='name')),
                ('description', models.TextField(blank=True, null=True, verbose_name='description')),
                ('visible', models.BooleanField(default=True, verbose_name='visible')),
                ('sequence', models.PositiveIntegerField(blank=True, null=True, verbose_name='sequence')),
                ('parent', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.ModuleCategory', verbose_name='parent')),
            ],
            bases=('base.element',),
        ),
        migrations.CreateModel(
            name='ModuleElement',
            fields=[
                ('element_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Element')),
            ],
            bases=('base.element',),
        ),
        migrations.AddField(
            model_name='element',
            name='groups',
            field=models.ManyToManyField(blank=True, to='auth.Group', verbose_name='groups'),
        ),
        migrations.AddField(
            model_name='element',
            name='users',
            field=models.ManyToManyField(blank=True, to='base.User', verbose_name='users'),
        ),
        migrations.AddField(
            model_name='country',
            name='language',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Language', verbose_name='language'),
        ),
        migrations.AddField(
            model_name='contact',
            name='country',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Country', verbose_name='country'),
        ),
        migrations.AddField(
            model_name='contact',
            name='language',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Language'),
        ),
        migrations.AddField(
            model_name='contact',
            name='parent',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Contact'),
        ),
        migrations.AddField(
            model_name='company',
            name='currency',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Currency', verbose_name='currency'),
        ),
        migrations.AddField(
            model_name='company',
            name='parent_company',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Company'),
        ),
        migrations.AddField(
            model_name='user',
            name='companies',
            field=models.ManyToManyField(blank=True, help_text='user allowed companies', to='base.Company', verbose_name='allowed companies'),
        ),
        migrations.AddField(
            model_name='user',
            name='company',
            field=models.ForeignKey(blank=True, help_text='default user company', null=True, on_delete=katrid.db.models.deletion.CASCADE, related_name='+', to='base.Company', verbose_name='company'),
        ),
        migrations.AddField(
            model_name='user',
            name='contact',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Contact'),
        ),
        migrations.AddField(
            model_name='user',
            name='groups',
            field=models.ManyToManyField(blank=True, help_text='The groups this user belongs to. A user will get all permissions granted to each of their groups.', related_name='user_set', related_query_name='user', to='auth.Group', verbose_name='groups'),
        ),
        migrations.AddField(
            model_name='user',
            name='user_permissions',
            field=models.ManyToManyField(blank=True, help_text='Specific permissions for this user.', related_name='user_set', related_query_name='user', to='auth.Permission', verbose_name='user permissions'),
        ),
        migrations.CreateModel(
            name='Action',
            fields=[
                ('moduleelement_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.ModuleElement')),
                ('name', models.CharField(blank=True, max_length=128, null=True, unique=True, verbose_name='name')),
                ('short_description', models.CharField(blank=True, max_length=32, null=True, verbose_name='short description')),
                ('description', models.CharField(blank=True, max_length=256, null=True, verbose_name='description')),
                ('action_type', models.CharField(blank=True, max_length=32, null=True, verbose_name='type')),
                ('context', models.TextField(blank=True, null=True, verbose_name='context')),
            ],
            options={
                'verbose_name': 'action',
                'verbose_name_plural': 'actions',
            },
            bases=('base.moduleelement',),
        ),
        migrations.CreateModel(
            name='Menu',
            fields=[
                ('moduleelement_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.ModuleElement')),
                ('name', models.CharField(blank=True, db_index=True, max_length=128, null=True, verbose_name='name')),
                ('description', models.TextField(blank=True, null=True, verbose_name='description')),
                ('icon', models.CharField(blank=True, help_text='menu icon class', max_length=256, null=True, verbose_name='icon')),
                ('sequence', models.PositiveIntegerField(blank=True, db_index=True, default=0, help_text='menu item sequence', null=True, verbose_name='sequence')),
            ],
            options={
                'ordering': ('sequence', 'id'),
                'verbose_name': 'menu item',
                'verbose_name_plural': 'menu items',
            },
            bases=('base.moduleelement',),
        ),
        migrations.CreateModel(
            name='Report',
            fields=[
                ('moduleelement_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.ModuleElement')),
                ('name', models.CharField(blank=True, max_length=256, null=True, unique=True, verbose_name='name')),
                ('description', models.CharField(blank=True, max_length=256, null=True, verbose_name='description')),
                ('definition', models.TextField(blank=True, null=True, verbose_name='definition')),
            ],
            options={
                'verbose_name': 'report',
            },
            bases=('base.moduleelement',),
        ),
        migrations.CreateModel(
            name='View',
            fields=[
                ('moduleelement_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.ModuleElement')),
                ('name', models.CharField(blank=True, max_length=128, null=True, unique=True, verbose_name='name')),
                ('priority', models.SmallIntegerField(blank=True, default=32, null=True, verbose_name='priority')),
                ('description', models.TextField(blank=True, null=True, verbose_name='description')),
                ('view_type', models.CharField(blank=True, default='tree', max_length=16, null=True, verbose_name='type')),
                ('definition', models.TextField(blank=True, null=True, verbose_name='definition')),
                ('ancestor', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.View', verbose_name='ancestor view')),
                ('content_type', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType', verbose_name='model')),
            ],
            options={
                'verbose_name': 'view',
                'verbose_name_plural': 'views',
            },
            bases=('base.moduleelement',),
        ),
        migrations.AlterUniqueTogether(
            name='userdata',
            unique_together=set([('user', 'key')]),
        ),
        migrations.AlterUniqueTogether(
            name='translation',
            unique_together=set([('content_type', 'name')]),
        ),
        migrations.AlterUniqueTogether(
            name='state',
            unique_together=set([('country', 'name'), ('country', 'code')]),
        ),
        migrations.AddField(
            model_name='moduleelement',
            name='module',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Module', verbose_name='module'),
        ),
        migrations.AddField(
            model_name='module',
            name='category',
            field=models.ForeignKey(blank=True, help_text='Module category', null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.ModuleCategory', verbose_name='category'),
        ),
        migrations.AddField(
            model_name='group',
            name='module_category',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.ModuleCategory', verbose_name='category'),
        ),
        migrations.CreateModel(
            name='ReportAction',
            fields=[
                ('action_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Action')),
                ('report', models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Report', verbose_name='report')),
            ],
            options={
                'verbose_name': 'report action',
                'verbose_name_plural': 'report actions',
                'db_table': 'base_report_action',
            },
            bases=('base.action',),
        ),
        migrations.CreateModel(
            name='URLAction',
            fields=[
                ('action_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Action')),
                ('url', models.URLField(blank=True, help_text='target URL', null=True, verbose_name='URL')),
                ('target', models.CharField(blank=True, max_length=32, null=True, verbose_name='target')),
            ],
            options={
                'verbose_name': 'URL action',
                'verbose_name_plural': 'URL actions',
                'db_table': 'base_url_action',
            },
            bases=('base.action',),
        ),
        migrations.CreateModel(
            name='ViewAction',
            fields=[
                ('action_ptr', models.OneToOneField(auto_created=True, on_delete=katrid.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='base.Action')),
                ('target', models.CharField(blank=True, choices=[('window', 'Current Window'), ('dialog', 'Dialog'), ('new', 'New Window'), ('popup', 'Browser Popup')], max_length=16, null=True, verbose_name='target')),
                ('mode', models.CharField(blank=True, choices=[('form', 'Form'), ('list', 'List'), ('chart', 'Chart'), ('calendar', 'Calendar'), ('kanban', 'Kanban')], default='list', max_length=16, null=True, verbose_name='initial view')),
                ('types', models.CharField(blank=True, max_length=64, null=True, verbose_name='view types')),
                ('state', models.CharField(blank=True, max_length=16, null=True, verbose_name='state')),
                ('content_type', models.ForeignKey(blank=True, help_text='Model to show', null=True, on_delete=katrid.db.models.deletion.CASCADE, to='contenttypes.ContentType', verbose_name='model')),
                ('view', models.ForeignKey(blank=True, help_text='View to show', null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.View', verbose_name='view')),
            ],
            options={
                'verbose_name': 'form action',
                'verbose_name_plural': 'form actions',
                'db_table': 'base_view_action',
            },
            bases=('base.action',),
        ),
        migrations.AddField(
            model_name='menu',
            name='action',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Action', verbose_name='action'),
        ),
        migrations.AddField(
            model_name='menu',
            name='parent',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.Menu', verbose_name='parent'),
        ),
        migrations.AddField(
            model_name='customview',
            name='view',
            field=models.ForeignKey(blank=True, null=True, on_delete=katrid.db.models.deletion.CASCADE, to='base.View', verbose_name='view'),
        ),
    ]

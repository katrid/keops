import os
from importlib import import_module
from katrid.db import connections
from katrid.db.utils import load_backend


def _create_connection(db):
    connection = connections[db]
    db_settings = connection.settings_dict
    db_engine = db_settings['ENGINE']
    backend = load_backend(db_engine)
    db_engine = db_engine.split('.')[-1]

    if db_engine == 'sqlite3':
        import sqlite3

        return sqlite3.connect(db_settings['NAME'])
    elif 'postgres' in db_engine:
        return backend.psycopg2.connect("host='%s'  dbname='postgres' user='%s' password='%s'" %
                                        (db_settings['HOST'], db_settings['USER'], db_settings['PASSWORD']))
    elif db_engine == 'pyodbc':
        return backend.Database.connect(
            "DRIVER={SQL Server Native Client 11.0};DATABASE=master;Server=%s;UID=%s;PWD=%s" %
            (db_settings['HOST'], db_settings['USER'], db_settings['PASSWORD']))
    elif db_engine == 'oracle':
        import cx_Oracle

        conn = cx_Oracle.connect('SYSTEM', db_settings['PASSWORD'], 'localhost/master')
        return conn


def createdb(db):
    connection = connections[db]
    db_settings = connection.settings_dict
    db_engine = db_settings['ENGINE']
    db_name = db_settings['NAME']
    db_engine = db_engine.split('.')[-1]

    conn = _create_connection(db)
    print('Creating db "%s"' % db_name)

    if db_engine == 'sqlite3':
        pass
    elif 'postgres' in db_engine:
        conn.autocommit = True
        conn.cursor().execute('''CREATE DATABASE %s ENCODING='UTF-8' ''' % db_name)
    elif db_engine == 'pyodbc':
        conn.autocommit = True
        conn.cursor().execute('''CREATE DATABASE %s''' % db_name)
        conn.autocommit = False
    elif db_engine == 'oracle':
        conn.cursor().execute('create user %s identified by %s' % (db_settings['USER'], db_settings['PASSWORD']))
        conn.cursor().execute('grant all privilege to %s' % db_settings['USER'])


def dropdb(db):
    connection = connections[db]
    connection.close()
    db_settings = connection.settings_dict
    db_engine = db_settings['ENGINE']
    db_name = db_settings['NAME']
    db_engine = db_engine.split('.')[-1]

    conn = _create_connection(db)
    print('Dropping db "%s"' % db_name)

    if db_engine == 'sqlite3':
        del conn
        if db_name != ':memory:':
            os.remove(db_name)
    elif db_engine.startswith('postgres'):
        conn.autocommit = True
        try:
            conn.cursor().execute('''DROP DATABASE %s''' % db_name)
        except Exception as e:
            print(e)
        conn.autocommit = False
    elif db_engine == 'pyodbc':
        conn.autocommit = True
        try:
            conn.cursor().execute('''DROP DATABASE %s''' % db_name)
        except Exception as e:
            print(e)
        conn.autocommit = False
    elif db_engine == 'oracle':
        try:
            conn.cursor().execute('DROP USER %s CASCADE' % db_settings['USER'])
        except Exception as e:
            print(e)


def syncdb(db):
    from katrid.core.management import call_command

    call_command('migrate', database=db, interactive=False)
    from katrid.conf import settings
    from katrid.utils import translation

    translation.activate(settings.LANGUAGE_CODE)


def recreatedb(db):
    dropdb(db)
    createdb(db)


def runfile(filename, db):
    f = open(filename, encoding='utf-8')
    conn = connections[db]
    conn.cursor().execute(f.read())


def install(app_name, db):
    from keops.modules.base import models as base
    from keops.routers.multidatabase import MultiDatabaseRouter

    app_list = []
    if not MultiDatabaseRouter._app_cache:
        MultiDatabaseRouter()._get_connection_apps(db)
    app_cache = MultiDatabaseRouter._app_cache[db]

    def install_app(app_name):
        app_name = app_name.replace('-', '_')
        app_label = app_name.split('.')[-1]
        if app_name in app_list or base.Module.objects.using(db).filter(app_label=app_label):
            #print('Application "%s" already installed on database "%s".' % (app_label, db))
            return
        # keep multidatabase app cache updated
        if not app_label in app_cache:
            app_cache.append(app_label)
        app_list.append(app_name)
        app = import_module(app_name)
        path = os.path.dirname(app.__file__)
        if hasattr(app, 'app_info'):
            info = app.app_info
        else:
            info = {'name': app_label, 'description': '', 'version': '0.1'}
        dependencies = info.get('dependencies', [])
        for dep in dependencies:
            install_app(dep)
        base.Module.objects.using(db).create(
            module_name=app_name,
            name=info['name'],
            app_label=app_label,
            description=info['description'],
            version=info.get('version', None),
            dependencies=info.get('dependencies'),
            icon=info.get('icon'),
            visible=info.get('visible'),
            tooltip=info.get('tooltip', ''),
            category=base.ModuleCategory.objects.get_category(info.get('category', None))
        )
        return True

    return install_app(app_name)

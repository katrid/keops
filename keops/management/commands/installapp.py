from optparse import make_option
from katrid.core.management.base import AppCommand
from katrid.db import DEFAULT_DB_ALIAS


class Command(AppCommand):
    help = 'Install modules for the given app name(s).'

    option_list = AppCommand.option_list + (
        make_option('--database', action='store', dest='database',
            default=DEFAULT_DB_ALIAS, help='Nominates a database to install the '
                'module. Defaults to the "default" database.'),
    )

    output_transaction = True

    def handle_app(self, app, **options):
        from keops.db import scripts
        db = options['database']
        if scripts.install('.'.join(app.__name__.split('.')[:-1]), db):
            scripts.syncdb(db)
            print('Application "%s" successfully installed on database "%s".' % (app.__name__.split('.')[-2], db))

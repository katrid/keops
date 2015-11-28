from optparse import make_option
from katrid.core.management import call_command
from katrid.core.management.base import BaseCommand, CommandError
from katrid.db import DEFAULT_DB_ALIAS, connections


class Command(BaseCommand):
    option_list = BaseCommand.option_list + (
        make_option('--database', action='store', dest='database',
            default=DEFAULT_DB_ALIAS, help='Specifies the database to use. Default is "default".'),
    )
    help = 'Forced drop and create a database. BE CAREFUL, THIS OPERATION CANNOT BE UNDONE!'

    def handle(self, *args, **options):
        from keops.db import scripts
        db = options['database']
        verbosity = options['verbosity']
        scripts.dropdb(db)
        call_command('createdb', verbosity=verbosity, database=db)

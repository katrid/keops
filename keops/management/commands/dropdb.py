from optparse import make_option

from katrid.core.management.base import BaseCommand
from katrid.db import DEFAULT_DB_ALIAS


class Command(BaseCommand):
    option_list = BaseCommand.option_list + (
        make_option('--database', action='store', dest='database',
            default=DEFAULT_DB_ALIAS, help='Specifies the database to use. Default is "default".'),
    )
    help = 'Forced drop database. BE CAREFUL, THIS OPERATION CANNOT BE UNDONE!'

    def handle(self, *args, **options):
        from keops.db import scripts
        scripts.dropdb(options['database'])

import sys
import os
os.environ.setdefault('KATRID_SETTINGS_MODULE', 'keops.settings')

import katrid.core.app
from keops import addons


class Application(katrid.core.app.Application):
    def __init__(self, settings=None, debug=False):
        super(Application, self).__init__(settings, debug)
        addons.setup()


if __name__ == '__main__':
    app = Application(debug=True)
    app.execute_from_command_line(sys.argv)

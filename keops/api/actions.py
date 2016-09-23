

class Action:
    action_type = None

    def __init__(self, name):
        self.name = name


class WindowAction(Action):
    action_type = 'sys.action.window'

    def __init__(self, name, info):
        super(WindowAction, self).__init__(name)
        self.info = info

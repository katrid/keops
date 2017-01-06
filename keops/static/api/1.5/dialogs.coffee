
class Alerts
  success: (msg) ->
    toastr['success'](msg)

  warn: (msg) ->
    toastr['warning'](msg)

  error: (msg) ->
    toastr['error'](msg)


Katrid.Dialogs =
  Alerts: new Alerts()

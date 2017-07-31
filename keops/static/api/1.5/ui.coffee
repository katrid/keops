uiKatrid = angular.module('ui-katrid', [])


class View extends Katrid.Services.Model
  constructor: ->
    super 'ui.view'

  fromModel: (model) ->
    @post('from_model', null, {model: model})

@Katrid.UI =
  View: View
  keyCode:
    BACKSPACE: 8
    COMMA: 188
    DELETE: 46
    DOWN: 40
    END: 35
    ENTER: 13
    ESCAPE: 27
    HOME: 36
    LEFT: 37
    PAGE_DOWN: 34
    PAGE_UP: 33
    PERIOD: 190
    RIGHT: 39
    SPACE: 32
    TAB: 9
    UP: 38
  

@Katrid.uiKatrid = uiKatrid

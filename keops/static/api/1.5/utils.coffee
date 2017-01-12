
if not String.prototype.format
  String.prototype.format = ->
    args = arguments
    @replace(/{(\d+)}/g, (match, number) ->
      if typeof args[number] isnt 'undefined' then args[number] else match
    )


Katrid.$hashId = 0

_.mixin
  hash: (obj) ->
    if not obj.$hashId
      obj.$hashId = ++Katrid.$hashId
    return obj.$hashId



class Application
  constructor: (@title) ->
  auth:
    user: {}
    isAuthenticated: false
    logout: (next) ->
      console.log(next)


Katrid.Application = Application

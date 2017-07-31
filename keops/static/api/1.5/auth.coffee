
SESSION_USER_KEY = '_katridUser'

class Auth
  user: null
  constructor: ->
    @user = JSON.parse(window.sessionStorage.getItem(SESSION_USER_KEY))
    if not @user?
      @user = {'is_authenticated': false}

  login: (username, password) ->
    rpcName = Katrid.Settings.server + '/api/auth/login/'
    $.ajax
      method: 'POST'
      url: rpcName
      data: JSON.stringify({'username': username, 'password': password})
      contentType: "application/json; charset=utf-8"
      dataType: 'json'
    .success (res) ->
      console.log(res)
      window.sessionStorage.setItem(SESSION_USER_KEY, JSON.stringify(res.result))

  loginRequired: (path, urls, next) ->
    if (path in urls and @user.is_authenticated) or (path not in urls)
      return true
    else
      return false

  isAuthenticated: ->
    rpcName = Katrid.Settings.server + '/api/auth/login/'
    $.get(rpcName)


Katrid.Auth = new Auth()

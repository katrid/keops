
ngApp = angular.module('katridApp', ['ngRoute', 'ngCookies', 'ngSanitize', 'ui-katrid'].concat(Katrid.Bootstrap.additionalModules))

ngApp.config ($interpolateProvider) ->
  $interpolateProvider.startSymbol '${'
  $interpolateProvider.endSymbol '}'


ngApp.factory 'actions', ->
  get: (service, id) ->
    if id
      return $.get("/web/action/#{service}/#{id}/" )
    else
      return $.get("/web/action/#{service}/")


ngApp.config ($routeProvider) ->
  $routeProvider
  .when('/action/:actionId/', {
    controller: 'ActionController'
    reloadOnSearch: false
    resolve:
      action: ['actions', '$route', (actions, $route) ->
        return actions.get($route.current.params.actionId)
      ]
    template: "<div id=\"katrid-action-view\">#{Katrid.i18n.gettext 'Loading...'}</div>"
  })
  .when('/action/:service/:actionId/', {
    controller: 'ActionController'
    reloadOnSearch: false
    resolve:
      action: ['actions', '$route', (actions, $route) ->
        return actions.get($route.current.params.service, $route.current.params.actionId)
      ]
    template: "<div id=\"katrid-action-view\">#{Katrid.i18n.gettext 'Loading...'}</div>"
  })
  return


ngApp.controller 'BasicController', ($scope, $compile, $location) ->
  $scope.compile = $compile
  $scope.Katrid = Katrid


ngApp.controller 'ActionController', ($scope, $compile, action, $location) ->
  $scope.Katrid = Katrid
  $scope.data = null
  $scope.location = $location
  $scope.record = null
  $scope.recordIndex = null
  $scope.recordId = null
  $scope.records = null
  $scope.viewType = null
  $scope.recordCount = 0
  $scope.dataSource = new Katrid.Data.DataSource($scope)
  $scope.compile = $compile

  $scope.$on '$routeUpdate', ->
    $scope.action.routeUpdate($location.$$search)

  $scope.$set = (field, value) ->
    control = $scope.form[field]
    control.$setViewValue value
    control.$render()
    return

  $scope.setContent = (content) ->
    $('html, body').animate({ scrollTop: 0 }, 'fast')
    $scope.content = $(content)
    el = angular.element('#katrid-action-view').html($compile($scope.content)($scope))

    # Get the first form controller
    $scope.formElement = el.find('form').first()
    $scope.form = $scope.formElement.controller('form')

  init = (action) ->
    if action
      if action.model
        $scope.model = new Katrid.Services.Model(action.model[1])
      $scope.action = act = new Katrid.Actions[action.action_type](action, $scope)
      act.routeUpdate($location.$$search)

  init(action)


@Katrid.ngApp = ngApp

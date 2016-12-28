
ngApp = angular.module('katridApp', ['ngRoute', 'ngCookies', 'ngSanitize', 'ui-katrid'])

ngApp.config ($interpolateProvider) ->
  $interpolateProvider.startSymbol('${')
  $interpolateProvider.endSymbol('}')


ngApp.factory 'actions', ->
  get: (service, id) ->
    if id
      $.get("/web/action/#{service}/#{id}/" )
    else
      $.get("/web/action/#{id}/")


ngApp.config ($routeProvider) ->
  $routeProvider
  .when('/action/:actionId', {
    controller: 'ActionController'
    reloadOnSearch: false
    resolve:
      action: ['actions', '$route', (actions, $route) ->
        return actions.get($route.current.params.actionId)
      ]
    template: "<div id=\"katrid-action-view\">#{Katrid.i18n.gettext 'Loading...'}</div>"
  })
  .when('/action/:service/:actionId', {
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

  $scope.$on('$routeUpdate', ->
    $scope.action.routeUpdate($location.$$search)
  )

  $scope.setContent = (content) ->
    $scope.content = content
    angular.element('#katrid-action-view').html($compile(content)($scope))

  init = (action) ->
    if action
      $scope.model = new Katrid.Services.Model(action.model[1])
      $scope.action = act = new Katrid.Actions[action.action_type](action, $scope)
      act.routeUpdate($location.$$search)

  init(action)


@Katrid.ngApp = ngApp


ngApp = angular.module('katridApp', ['ngRoute', 'ngCookies', 'ngSanitize', 'ui-katrid'].concat(Katrid.Bootstrap.additionalModules))

ngApp.config ($interpolateProvider) ->
  $interpolateProvider.startSymbol '${'
  $interpolateProvider.endSymbol '}'

ngApp.run ['$route', '$rootScope', '$location', ($route, $rootScope, $location) ->
  original = $location.path
  $location.path = (path, currentAction, back) ->
    if currentAction is false
      reload = false
    else
      reload = true

    if currentAction?
      lastRoute = $route.current
      un = $rootScope.$on '$locationChangeSuccess', ->
        if $route.current
          $route.current.currentAction = currentAction
          $route.current.reload = reload
          $route.current.back = back
        un()
    return original.apply($location, [path])
]


ngApp.factory 'actions', ->
  get: (service, id) ->
    return $.get("/web/action/#{service}/#{id}/" )

actionTempl = """<div id="katrid-action-view"><h1 class="ajax-loading-animation margin-left-8"><i class="fa fa-cog fa-spin"></i> ${ Katrid.i18n.gettext('Loading...') }</h1></div>"""

ngApp.config ($routeProvider) ->
  $routeProvider
  .when('/action/:actionId/', {
    controller: 'ActionController'
    reloadOnSearch: false
    resolve:
      action: ['$route', ($route) ->
        if $route.current.back
          $route.current.back.info._back = $route.current.back
          return $route.current.back.info
        return $.get("/web/action/#{ $route.current.params.actionId }/")
      ]
    template: actionTempl
  })
  .when('/action/:service/view/', {
    controller: 'ActionController'
    reloadOnSearch: false
    resolve:
      action: ['actions', '$route', (actions, $route) ->
        params = $route.current.params
        return {
          model: [null, $route.current.params.service]
          action_type: "sys.action.window"
          view_mode: 'form'
          object_id: params.id
          display_name: params.title
          _currentAction: $route.current.currentAction
        }
      ]
    template: actionTempl
  })
  return


ngApp.controller 'BasicController', ($scope, $compile, $location) ->
  $scope.compile = $compile
  $scope.Katrid = Katrid


class DialogLocation
  constructor: ->
    @$$search = {}
  search: ->


ngApp.controller 'ActionController', ($scope, $compile, $location, $route, action) ->
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

  $scope.$set = (field, value) ->
    control = $scope.form[field]
    if control
      control.$setViewValue value
      control.$render()
    else
      $scope.record[field] = value
    return

  $scope.setContent = (content) ->
    $('html, body').animate({ scrollTop: 0 }, 'fast')
    content = $scope.content = $(content)

    ## Prepare form special elements
    # Prepare form header
    header = content.find('form header').first()

    el = root.html($compile($scope.content)($scope))

    # Get the first form controller
    $scope.formElement = el.find('form').first()
    $scope.form = $scope.formElement.controller('form')

    # Add form header
    if header
      newHeader = el.find('header').first()
      newHeader.replaceWith($compile(header)($scope))
      for child in header.children()
        child = $(child)
        #newHeader.append(child)
        if not child.attr('class')
          child.addClass('btn btn-default')
        if child.prop('tagName') is 'BUTTON' and child.attr('type') is 'object'
          child.attr('type', 'button')
          child.attr('button-type', 'object')
          child.click(doButtonClick)
        else if child.prop('tagName') is 'BUTTON' and not child.attr('type')
          child.attr('type', 'button')

  doButtonClick = ->
    btn = $(this)
    meth = btn.prop('name')
    $scope.model.post(meth, { id: $scope.record.id })
    .done (res) ->
      console.log('do button click', res)

  $scope.getContext = ->
    JSON.parse($scope.action.info.context)

  init = (action) ->
    # Check if there's a history/back information
    if $scope.isDialog
      location = new DialogLocation()
    else
      location = $location

    $scope.action = act = new Katrid.Actions[action.action_type](action, $scope, location)
    if action.model
      $scope.model = new Katrid.Services.Model(action.model[1])
      if action._back and action._back.views
        act.views = action._back.views
        $scope.views = act.views
        delete action._back
      else
        act.views = $scope.views

    if $scope.isDialog
      act.isDialog = $scope.isDialog
    if $scope.parentAction
      act.parentAction = $scope.parentAction
    if act and act.isDialog
      act.routeUpdate({ view_type: action.view_type })
      act.createNew()
    else
      act.routeUpdate($location.$$search)

  # Check if the element is a child
  if $scope.parentAction
    root = $scope.root
  else
    root = angular.element('#katrid-action-view')
    $scope.$on '$routeUpdate', ->
      $scope.action.routeUpdate($location.$$search)
  init(action)


@Katrid.ngApp = ngApp

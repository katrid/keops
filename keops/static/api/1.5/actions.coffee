
class Action
  actionType: null
  constructor: (@info, @scope) ->
    @location = @scope.location
  apply: ->
  execute: (scope) ->


class WindowAction extends Action
  @actionType: 'sys.action.window'
  constructor: (info, scope) ->
    super info, scope
    @viewMode = info.view_mode
    @viewModes = @viewMode.split(',')
    @viewType = null
    @cachedViews = {}

  createNew: ->
    @setViewType('form')
    @scope.dataSource.state = 'CREATING'
    @scope.record = {}
    @scope.record.display_name = Katrid.i18n.gettext '(New)'

  deleteSelection: ->
    if confirm(Katrid.i18n.gettext 'Confirm delete record?')
      @scope.model.destroy(@scope.record.id)
      i = @scope.records.indexOf(@scope.record)
      if i
        @scope.search({})
      @setViewType('list')

  routeUpdate: (search) ->
    if search.view_type?
      if not @scope.records?
        @scope.records = []
      if @viewType != search.view_type
        @viewType = search.view_type
        @execute()

      if search.view_type is 'list' and not search.page
        @location.search('page', 1)
        return

      if search.view_type is 'list' and search.page isnt @scope.dataSource.pageIndex
        @scope.dataSource.pageIndex = search.page
        @scope.dataSource.search({}, search.page)

      if search.id and ((@scope.record? and @scope.record.id != search.id) or not @scope.record?)
        @scope.record = null
        @scope.dataSource.get(search.id)
    else
      @setViewType(@viewModes[0])

  setViewType: (viewType) ->
    @location.search
      view_type: viewType

  apply: ->
    @render(@scope, @scope.view.content, @viewType)

  execute: ->
    scope = @scope
    me = @
    #view = @cachedViews[@viewType]
    # TODO CACHED VIEWS
    view = null
    if view
      scope.view = view
      me.apply()
    else
      r = @scope.model.getViewInfo({ view_type: @viewType })
      r.done (res) ->
        view = res.result
        me.cachedViews[me.viewType] = view
        me.scope.$apply ->
          me.scope.view = view
          me.apply()
      return r

  render: (scope, html, viewType) ->
    scope.setContent(Katrid.UI.Utils.Templates['render_' + viewType](scope, html))

  doViewAction: (viewAction, target) ->
    @scope.model.doViewAction({ action_name: viewAction, target: target })
    .done (res) ->
      console.log(res)
      if res.status is 'open'
        window.open(res.open)


@Katrid.Actions =
  Action: Action
  WindowAction: WindowAction

@Katrid.Actions[WindowAction.actionType] = WindowAction

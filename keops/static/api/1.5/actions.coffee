
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

  createNew: ->
    @setViewType('form')
    @scope.dataSource.newRecord()

  deleteSelection: ->
    if confirm(Katrid.i18n.gettext 'Confirm delete record?')
      @scope.model.destroy(@scope.record.id)
      i = @scope.records.indexOf(@scope.record)
      if i
        @scope.dataSource.search({})
      @setViewType('list')

  copy: ->
    @setViewType('form')
    @scope.dataSource.copy(@scope.record.id)
    return false

  routeUpdate: (search) ->
    if search.view_type?
      if not @scope.records?
        @scope.records = []
      if @viewType != search.view_type
        @scope.dataSource.pageIndex = null
        @scope.record = null
        @viewType = search.view_type
        @execute()

      if search.view_type is 'list' and not search.page
        @location.search('page', 1)
        return

      filter = {}
      if search.q?
        filter.q = search.q

      if search.view_type is 'list' and search.page isnt @scope.dataSource.pageIndex
        @scope.dataSource.pageIndex = parseInt(search.page)
        @scope.dataSource.search(filter, search.page)
      else if search.view_type is 'list' and search.q?
        @scope.dataSource.search(filter, search.page)

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
    if @views?
      @scope.view = @views[@viewType]
      @apply()
    else
      r = @scope.model.loadViews()
      r.done (res) =>
        views = res.result
        @views = views
        @scope.$apply =>
          @scope.views = views
          @scope.view = views[@viewType]
          @apply()
      return r

  render: (scope, html, viewType) ->
    scope.setContent(Katrid.UI.Utils.Templates['preRender_' + viewType](scope, html))

  searchText: (q) ->
    @location.search('q', q)

  _prepareParams: (params) ->
    r = {}
    for p in params
      if p.field and p.field.type is 'ForeignKey'
        r[p.field.name] = p.id
      else
        r[p.id.name + '__icontains'] = p.text
    return r

  setSearchParams: (params) ->
    data = @_prepareParams(params)
    @scope.dataSource.search(data)

  doViewAction: (viewAction, target, confirmation) ->
    if not confirmation or (confirmation and confirm(confirmation))
      @scope.model.doViewAction({ action_name: viewAction, target: target })
      .done (res) ->
        console.log(res)
        if res.status is 'open'
          window.open(res.open)
        else if res.status is 'fail'
          for msg in res.messages
            Katrid.Dialogs.Alerts.error msg
        else if res.status is 'ok' and res.result.messages
          for msg in res.result.messages
            Katrid.Dialogs.Alerts.success msg


class ReportAction extends Action
  @actionType: 'sys.action.report'
  routeUpdate: (search) ->
    @scope.setContent(@info.content)


class ViewAction extends Action
  @actionType = 'sys.action.view'
  routeUpdate: (search) ->
    @scope.setContent(@info.content)


@Katrid.Actions =
  Action: Action
  WindowAction: WindowAction
  ReportAction: ReportAction
  ViewAction: ViewAction

@Katrid.Actions[WindowAction.actionType] = WindowAction
@Katrid.Actions[ReportAction.actionType] = ReportAction
@Katrid.Actions[ViewAction.actionType] = ViewAction

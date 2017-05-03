

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
        return

      if search.view_type in ['list', 'card'] and not search.page
        @location.search('page', 1)
      else

        filter = {}
        if search.q?
          filter.q = search.q

        fields = _.keys(@scope.view.fields)

        if search.view_type in ['list', 'card'] and search.page isnt @scope.dataSource.pageIndex
          @scope.dataSource.pageIndex = parseInt(search.page)
          @scope.dataSource.search(filter, search.page, fields)
        else if search.view_type in ['list', 'card'] and search.q?
          @scope.dataSource.search(filter, search.page, fields)

        if search.id and ((@scope.record? and @scope.record.id != search.id) or not @scope.record?)
          console.log('set id', search.id)
          @scope.record = null
          @scope.dataSource.get(search.id)
    else
      @setViewType(@viewModes[0])
    return

  setViewType: (viewType) ->
    @location.search
      view_type: viewType

  apply: ->
    @render(@scope, @scope.view.content, @viewType)
    @routeUpdate(@location.$$search)

  execute: ->
    if @views?
      @scope.view = @views[@viewType]
      @apply()
    else
      r = @scope.model.loadViews
        views: @info.views
        action: @info.id
      r.done (res) =>
        views = res.result
        @views = views
        @scope.$apply =>
          @scope.views = views
          @scope.view = views[@viewType]
          @apply()

    if @viewType isnt 'list'
      @scope.dataSource.groupBy()


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
    #data = @_prepareParams(params)
    @scope.dataSource.search(params)

  applyGroups: (groups) ->
    @scope.dataSource.groupBy(groups[0])

  doViewAction: (viewAction, target, confirmation, prompt) ->
    @_doViewAction(@scope, viewAction, target, confirmation, prompt)

  _doViewAction: (scope, viewAction, target, confirmation, prompt) ->
    promptValue = null
    if prompt
      promptValue = window.prompt(prompt)
    if not confirmation or (confirmation and confirm(confirmation))
      scope.model.doViewAction({ action_name: viewAction, target: target, prompt: promptValue })
      .done (res) ->
        if res.status is 'open'
          window.open(res.open)
        else if res.status is 'fail'
          for msg in res.messages
            Katrid.Dialogs.Alerts.error msg
        else if res.status is 'ok' and res.result.messages
          for msg in res.result.messages
            Katrid.Dialogs.Alerts.success msg

  listRowClick: (index, row) ->
    if row._group
      row._group.expanded = not row._group.expanded
      row._group.collapsed = not row._group.expanded
      if row._group.expanded
        @scope.dataSource.expandGroup(index, row)
      else
        @scope.dataSource.collapseGroup(index, row)
    else
      @scope.dataSource.setRecordIndex(index)
      @location.search({view_type: 'form', id: row.id})

  autoReport: ->
    @scope.model.autoReport()
    .done (res) ->
      if res.ok and res.result.open
        window.open(res.result.open)


class ReportAction extends Action
  @actionType: 'sys.action.report'

  constructor: (info, scope) ->
    super info, scope
    @userReport = {}

  userReportChanged: (report) ->
    @location.search
      user_report: report

  routeUpdate: (search) ->
    console.log('report action', @info)
    @userReport.id = search.user_report
    if @userReport.id
      svc = new Katrid.Services.Model('sys.action.report')
      svc.post 'load_user_report', null, { kwargs: { user_report: @userReport.id } }
      .done (res) =>
        @userReport.params = res.result
        @scope.setContent(@info.content)
    else
      @scope.setContent(Katrid.Reports.Reports.renderDialog(@))
    return


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

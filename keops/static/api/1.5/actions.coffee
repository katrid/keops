
class Action
  actionType: null
  constructor: (@info, @scope, @location) ->
    @currentUrl =
      path: @location.$$path
      params: @location.$$search
    @history = []
    if @info._currentAction
      @history.push(@info._currentAction)

  openObject: (service, id, evt, title) ->
    evt.preventDefault()
    evt.stopPropagation()
    if (evt.ctrlKey)
      window.open(evt.target.href)
      return false
    url = """action/#{ service }/view/"""
    @location.path(url, @).search
      view_type: 'form'
      id: id
      title: title
    return false

  apply: ->
  backTo: (index) ->
    if index is -1
      h = @history[0]
      if h.backUrl
        location = h.backUrl
      else
        location = h.currentUrl
    else
      h = @history[index]
      location = h.currentUrl
    path = location.path
    params = location.search
    @location.path(path, false, h)
    .search(params)
  execute: (scope) ->
  getCurrentTitle: ->
    @info.display_name
  search: ->
    if not @isDialog
      console.log(arguments)
      @location.search.apply(null, arguments)


class WindowAction extends Action
  @actionType: 'sys.action.window'
  constructor: (info, scope, location) ->
    super info, scope, location
    @notifyFields = []
    @viewMode = info.view_mode
    @viewModes = @viewMode.split(',')
    @viewType = null

  registerFieldNotify: (field) ->
    # Add field to notification list
    if @notifyFields.indexOf(field.name) is -1
      @scope.$watch 'record.' + field.name, ->
        console.log('field changed', field)
      @notifyFields.push(fields)

  getCurrentTitle: ->
    if @viewType is 'form'
      return @scope.record.display_name
    return super()

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
    viewType = search.view_type

    # Emulate back to results page
    if @viewType and @viewType isnt 'form' and viewType is 'form'
      # Store main view type
      @backUrl = @currentUrl

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
        @location.search('limit', @info.limit)
      else

        filter = {}
        if search.q?
          filter.q = search.q

        fields = _.keys(@scope.view.fields)

        console.log(filter)
        if search.view_type in ['list', 'card'] and search.page isnt @scope.dataSource.pageIndex
          @scope.dataSource.pageIndex = parseInt(search.page)
          @scope.dataSource.limit = parseInt(search.limit)
          @scope.dataSource.search(filter, search.page, fields)
        else if search.view_type in ['list', 'card'] and search.q?
          @scope.dataSource.search(filter, search.page, fields)

        if search.id and ((@scope.record? and @scope.record.id != search.id) or not @scope.record?)
          @scope.record = null
          @scope.dataSource.get(search.id)
    else
      @setViewType(@viewModes[0])
    @currentUrl =
      url: @location.$$url
      path: @location.$$path
      search: @location.$$search
    if search.title
      @info.display_name = search.title
    return

  setViewType: (viewType) ->
    if @viewType is 'form' and not viewType and @backUrl
      return @location.path(@backUrl.path, false, @).search(@backUrl.search)
    else
      search = @location.$$search
      if viewType isnt 'form'
        delete search.id
      search.view_type = viewType
      return @location.search(search)

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
    if not @isDialog
      html = Katrid.UI.Utils.Templates['preRender_' + viewType](scope, html)
    scope.setContent(html)

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
    p = {}
    if @info.domain
      p = $.parseJSON(@info.domain)
    for k, v of p
      arg = {}
      arg[k] = v
      params.push(arg)
    console.log(params)
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

  listRowClick: (index, row, evt) ->
    search =
      view_type: 'form'
      id: row.id
    if evt.ctrlKey
      url = '#'+ @location.$$path + '?' + $.param(search)
      window.open(url)
      return
    if row._group
      row._group.expanded = not row._group.expanded
      row._group.collapsed = not row._group.expanded
      if row._group.expanded
        @scope.dataSource.expandGroup(index, row)
      else
        @scope.dataSource.collapseGroup(index, row)
    else
      @scope.dataSource.setRecordIndex(index)
      @location.search(search)
    return

  autoReport: ->
    @scope.model.autoReport()
    .done (res) ->
      if res.ok and res.result.open
        window.open(res.result.open)

  showDefaultValueDialog: ->
    html = Katrid.UI.Utils.Templates.getSetDefaultValueDialog()
    modal = $(@scope.compile(html)(@scope)).modal()
    modal.on 'hidden.bs.modal', ->
      $(@).data 'bs.modal', null
      $(@).remove()
    return


class ReportAction extends Action
  @actionType: 'sys.action.report'

  constructor: (info, scope, location) ->
    super info, scope, location
    @userReport = {}

  userReportChanged: (report) ->
    @location.search
      user_report: report

  routeUpdate: (search) ->
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


class UrlAction extends Action
  @actionType = 'sys.action.url'

  constructor: (info, scope, location) ->
    window.location.href = info.url


@Katrid.Actions =
  Action: Action
  WindowAction: WindowAction
  ReportAction: ReportAction
  ViewAction: ViewAction
  UrlAction: UrlAction

@Katrid.Actions[WindowAction.actionType] = WindowAction
@Katrid.Actions[ReportAction.actionType] = ReportAction
@Katrid.Actions[ViewAction.actionType] = ViewAction
@Katrid.Actions[UrlAction.actionType] = UrlAction

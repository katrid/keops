
_counter = 0


class Reports
  @currentReport = {}
  @currentUserReport = {}

  @get = (repName) ->

  @renderDialog = (action) ->
    Katrid.UI.Utils.Templates.renderReportDialog(action)


class Report
  constructor: (@action, @scope) ->
    @info = @action.info
    Katrid.Reports.Reports.currentReport = @
    if not Params.Labels?
      Params.Labels =
        exact: Katrid.i18n.gettext 'Is equal'
        in: Katrid.i18n.gettext 'Selection'
        contains: Katrid.i18n.gettext 'Contains'
        startswith: Katrid.i18n.gettext 'Starting with'
        endswith: Katrid.i18n.gettext 'Ending with'
        gt: Katrid.i18n.gettext 'Greater-than'
        lt: Katrid.i18n.gettext 'Less-than'
        between: Katrid.i18n.gettext 'Between'
        isnull: Katrid.i18n.gettext 'Is Null'

    @name = @info.name
    @id = ++_counter
    @values = {}
    @params = []
    @filters = []
    @groupables = []
    @sortables = []
    @totals = []

  getUserParams: ->
    report = @
    params =
      data: []
      file: report.container.find('#id-report-file').val()
    for p in @params
      params.data.push
        name: p.name
        op: p.operation
        value1: p.value1
        value2: p.value2
        type: p.type

    fields = report.container.find('#report-id-fields').val()
    params['fields'] = fields

    totals = report.container.find('#report-id-totals').val()
    params['totals'] = totals

    sorting = report.container.find('#report-id-sorting').val()
    params['sorting'] = sorting

    grouping = report.container.find('#report-id-grouping').val()
    params['grouping'] = grouping

    params

  loadFromXml: (xml) ->
    if _.isString(xml)
      xml = $(xml)
    fields = []

    for f in xml.find('field')
      f = $(f)
      name = f.attr('name')
      label = f.attr('label') or (@info.fields[name] and @info.fields[name].caption) or name
      groupable = f.attr('groupable')
      sortable = f.attr('sortable')
      total = f.attr('total')
      param = f.attr('param')
      console.log(name, label, f)
      fields.push
        name: name
        label: label
        groupable: groupable
        sortable: sortable
        total: total
        param: param

    params = ($(p).attr('name') for p in xml.find('param'))

    @load(fields, params)

  saveDialog: ->
    params = @getUserParams()
    name = window.prompt(Katrid.i18n.gettext('Report name'), Katrid.Reports.Reports.currentUserReport.name)
    if name
      Katrid.Reports.Reports.currentUserReport.name = name
      $.ajax
        type: 'POST'
        url: @container.find('#report-form').attr('action') + '?save=' + name
        contentType: "application/json; charset=utf-8",
        dataType: 'json'
        data: JSON.stringify params
    false

  load: (fields, params) ->
    if not fields
      fields = @info.fields
    if not params
      params = []
    @fields = fields

    # Create params
    for p in fields
      if p.groupable
        @groupables.push(p)
      if p.sortable
        @sortables.push(p)
      if p.total
        @totals.push(p)
      p.autoCreate = p.name in params

  loadParams: ->
    console.log('load params', @fields)
    for p in @fields
      if p.autoCreate
        @addParam(p.name)

  addParam: (paramName) ->
    for p in @fields
      if p.name is paramName
        p = new Param(p, @)
        @params.push(p)
        #$(p.render(@elParams))
        break

  getValues: ->


  export: (format='pdf') ->
    params = @getUserParams()
    svc = new Katrid.Services.Model('sys.action.report')
    svc.post 'export_report', null, { args: [@info.id], kwargs: { format: format, params: params } }
    .done (res) ->
      if res.result.open
        window.open res.result.open
    false

  preview: ->
    @export()

  renderFields: ->
    el = $('<div></div>')
    flds = ("""<option value="#{p.name}">#{p.label}</option>""" for p in @fields).join('')
    aggs = ("""<option value="#{p.name}">#{p.label}</option>""" for p in @fields when p.total).join('')
    el = @container.find('#report-params')
    sel = el.find('#report-id-fields')
    sel.append($(flds))
    .select2({ tags: ({id: p.name, text: p.label} for p in @fields) })
    .select2("container").find("ul.select2-choices").sortable
        containment: 'parent'
        start: -> sel.select2("onSortStart")
        update: -> sel.select2("onSortEnd")
    if Katrid.Reports.Reports.currentUserReport.params and Katrid.Reports.Reports.currentUserReport.params.fields
      console.log(Katrid.Reports.Reports.currentUserReport.params.fields)
      sel.select2('val', Katrid.Reports.Reports.currentUserReport.params.fields)
    #sel.data().select2.updateSelection([{ id: 'vehicle', text: 'Vehicle'}])
    sel = el.find('#report-id-totals')
    sel.append(aggs)
    .select2({ tags: ({ id: p.name, text: p.label } for p in @fields when p.total) })
    .select2("container").find("ul.select2-choices").sortable
        containment: 'parent'
        start: -> sel.select2("onSortStart")
        update: -> sel.select2("onSortEnd")
    return el

  renderParams: (container) ->
    el = $('<div></div>')
    @elParams = el
    loaded = {}

    userParams = Katrid.Reports.Reports.currentUserReport.params
    if userParams and userParams.data
      for p in userParams.data
        loaded[p.name] = true
        @addParam(p.name, p.value)

    for p in @params
      if p.static and not loaded[p.name]
        $(p.render(el))
    container.find('#params-params').append(el)

  renderGrouping: (container) ->
    opts = ("""<option value="#{p.name}">#{p.label}</option>""" for p in @groupables).join('')
    el = container.find("#params-grouping")
    sel = el.find('select').select2()
    sel.append(opts)
    .select2("container").find("ul.select2-choices").sortable
        containment: 'parent'
        start: -> sel.select2("onSortStart")
        update: -> sel.select2("onSortEnd")

  renderSorting: (container) ->
    opts = ("""<option value="#{p.name}">#{p.label}</option>""" for p in @sortables when p.sortable).join('')
    el = container.find("#params-sorting")
    sel = el.find('select').select2()
    sel.append(opts)
    .select2("container").find("ul.select2-choices").sortable
        containment: 'parent'
        start: -> sel.select2("onSortStart")
        update: -> sel.select2("onSortEnd")

  render: (container) ->
    @container = container
    el = @renderFields()
    if @sortables.length
      el = @renderSorting(container)
    else
      container.find("#params-sorting").hide()

    if @groupables.length
      el = @renderGrouping(container)
    else
      container.find("#params-grouping").hide()

    el = @renderParams(container)


class Params
  @Operations =
    exact: 'exact'
    in: 'in'
    contains: 'contains'
    startswith: 'startswith'
    endswith: 'endswith'
    gt: 'gt'
    lt: 'lt'
    between: 'between'
    isnull: 'isnull'

  @DefaultOperations =
    CharField: @Operations.exact
    IntegerField: @Operations.exact
    DateTimeField: @Operations.between
    DateField: @Operations.between
    FloatField: @Operations.between
    DecimalField: @Operations.between
    ForeignKey: @Operations.exact
    sqlchoices: @Operations.exact

  @TypeOperations =
    CharField: [@Operations.exact, @Operations.in, @Operations.contains, @Operations.startswith, @Operations.endswith, @Operations.isnull]
    IntegerField: [@Operations.exact, @Operations.in, @Operations.gt, @Operations.lt, @Operations.between, @Operations.isnull]
    FloatField: [@Operations.exact, @Operations.in, @Operations.gt, @Operations.lt, @Operations.between, @Operations.isnull]
    DecimalField: [@Operations.exact, @Operations.in, @Operations.gt, @Operations.lt, @Operations.between, @Operations.isnull]
    DateTimeField: [@Operations.exact, @Operations.in, @Operations.gt, @Operations.lt, @Operations.between, @Operations.isnull]
    DateField: [@Operations.exact, @Operations.in, @Operations.gt, @Operations.lt, @Operations.between, @Operations.isnull]
    ForeignKey: [@Operations.exact, @Operations.in, @Operations.isnull]
    sqlchoices: [@Operations.exact, @Operations.in, @Operations.isnull]

  @Widgets =
    CharField: (param) ->
      """<div><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}" ng-model="param.value1" type="text" class="form-control"></div>"""

    IntegerField: (param) ->
      secondField = ''
      if param.operation is 'between'
        secondField = """<div class="col-xs-6"><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}-2" ng-model="param.value2" type="text" class="form-control"></div>"""
      """<div class="row"><div class="col-sm-6"><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}" type="number" ng-model="param.value1" class="form-control"></div>#{secondField}</div>"""

    DecimalField: (param) ->
      secondField = ''
      if param.operation is 'between'
        secondField = """<div class="col-xs-6"><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}-2" ng-model="param.value2" type="text" class="form-control"></div>"""
      """<div class="col-sm-6"><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}" type="number" ng-model="param.value1" class="form-control"></div>#{secondField}"""

    DateTimeField: (param) ->
      secondField = ''
      if param.operation is 'between'
        secondField = """<div class="col-xs-6"><label class="control-label">&nbsp;</label>
<div class="input-group date"><input id="rep-param-id-#{param.id}-2" datepicker ng-model="param.value2" class="form-control">
<div class="input-group-addon"><span class="glyphicon glyphicon-th"></span></div>
</div>
</div>
"""
      """<div class="row">><div class="col-xs-6"><label class="control-label">&nbsp;</label><div class="input-group date"><input id="rep-param-id-#{param.id}" datepicker ng-model="param.value1" class="form-control"><div class="input-group-addon"><span class="glyphicon glyphicon-th"></span></div></div></div>#{secondField}</div"""

    DateField: (param) ->
      secondField = ''
      if param.operation is 'between'
        secondField = """<div class="col-xs-6"><label class="control-label">&nbsp;</label><div class="input-group date"><input id="rep-param-id-#{param.id}-2" datepicker ng-model="param.value2" class="form-control"><div class="input-group-addon"><span class="glyphicon glyphicon-th"></span></div></div></div>"""
      """<div class="row"><div class="col-xs-6"><label class="control-label">&nbsp;</label><div class="input-group date"><input id="rep-param-id-#{param.id}" datepicker ng-model="param.value1" class="form-control"><div class="input-group-addon"><span class="glyphicon glyphicon-th"></span></div></div></div>#{secondField}</div>"""

    ForeignKey: (param) ->
      serviceName = param.params.info.model
      multiple = ''
      if param.operation is 'in'
        multiple = 'multiple'
      """<div><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}" ajax-choices="/api/rpc/#{serviceName}/get_field_choices/" field="#{param.name}" ng-model="param.value1" #{multiple}></div>"""

    sqlchoices: (param) ->
      """<div><label class="control-label">&nbsp;</label><input id="rep-param-id-#{param.id}" ajax-choices="/api/reports/choices/" sql-choices="#{param.name}" ng-model="param.value1"></div>"""


class Param
  constructor: (@info, @params) ->
    @name = @info.name
    @label = @info.label
    @static = @info.param is 'static'
    @field = @params.info.fields and @params.info.fields[@name]
    @type = @info.type or (@field and @field.type) or 'CharField'
    if @info.sql_choices
      @type = 'sqlchoices'
    @defaultOperation = @info.default_operation or Params.DefaultOperations[@type]
    @operation = @defaultOperation
    # @operations = @info.operations or Params.TypeOperations[@type]
    @operations = @getOperations()
    @exclude = @info.exclude
    @id = ++_counter

  defaultValue: ->
    null

  setOperation: (op, focus=true) ->
    @createControls(@scope)
    el = @el.find('#rep-param-id-' + @id)
    if focus
      el.focus()
    return

  createControls: (scope) ->
    el = @el.find("#param-widget")
    el.empty()
    widget = Params.Widgets[@type](@)
    widget = @params.scope.compile(widget)(scope)
    el.append(widget)

  getOperations: -> ({ id: op, text: Params.Labels[op] }for op in Params.TypeOperations[@type])

  operationTemplate: ->
    opts = @getOperations()
    """<div class="col-sm-4"><label class="control-label">#{@label}</label><select id="param-op-#{@id}" ng-model="param.operation" ng-init="param.operation='#{@defaultOperation}'" class="form-control" onchange="$('#param-#{@id}').data('param').change();$('#rep-param-id-#{@id}')[0].focus()">
#{opts}
</select></div>"""

  template: ->
    operation = @operationTemplate()
    """<div id="param-#{@id}" class="row form-group" data-param="#{@name}" ng-controller="ParamController"><div class="col-sm-12">#{operation}<div id="param-widget-#{@id}"></div></div></div>"""

  render: (container) ->
    @el = @params.scope.compile(@template())(@params.scope)
    @el.data('param', @)
    @createControls(@el.scope())
    container.append(@el)


Katrid.uiKatrid.controller 'ReportController', ($scope, $element, $compile) ->
  xmlReport = $scope.$parent.action.info.content
  report = new Report($scope.$parent.action, $scope)
  $scope.report = report
  console.log(report)
  report.loadFromXml(xmlReport)
  report.render($element)
  report.loadParams()


Katrid.uiKatrid.controller 'ReportParamController', ($scope, $element) ->
  $scope.$parent.param.el = $element
  $scope.$parent.param.scope = $scope
  $scope.$parent.param.setOperation($scope.$parent.param.operation, false)


@Katrid.Reports =
  Reports: Reports
  Report: Report
  Param: Param


class RecordState
  @destroyed = 'destroyed'
  @created = 'created'
  @modified = 'modified'


class DataSourceState
  @inserting = 'inserting'
  @browsing = 'browsing'
  @editing = 'editing'
  @loading = 'loading'
  @inactive = 'inactive'


class DataSource
  constructor: (@scope) ->
    @recordIndex = 0
    @recordCount = null
    @loading = false
    @loadingRecord = false
    @masterSource = null
    @pageIndex = 0
    @pageLimit = 100
    @offset = 0
    @offsetLimit = 0
    @requestInterval = 300
    @pendingRequest = null
    @fieldName = null
    @children = []
    @modifiedData = null
    @uploading = 0
    @state = null
    @fieldChangeWatchers = []

  cancelChanges: ->
    #@scope.record = null
    #@scope.action.setViewType('list')
    @setState(DataSourceState.browsing)

  saveChanges: ->
    # Submit fields with dirty state only
    el = @scope.formElement
    if @validate()
      data = @getModifiedData(@scope.form, el, @scope.record)

      if data
        @uploading++
        @scope.model.write([data])
        .done (res) =>
          if res.ok
            @scope.form.$setPristine()
            @scope.form.$setUntouched()
            @setState(DataSourceState.browsing)
          else
            s = "<span>#{Katrid.i18n.gettext 'The following fields are invalid:'}<hr></span>"
            if res.message
              s = res.message
            else if res.messages
              for fld of res.messages
                msgs = res.messages[fld]
                field = @scope.view.fields[fld]
                elfield = el.find(""".form-field[name="#{field.name}"]""")
                elfield.addClass('ng-invalid ng-touched')
                s += "<strong>#{field.caption}</strong><ul>"
                console.log(field)
                for msg in msgs
                  s += "<li>#{msg}</li>"
                s += '</ul>'
              if elfield
                elfield.focus()

            Katrid.Dialogs.Alerts.error s
        .always =>
          @scope.$apply =>
            @uploading--
      else
        Katrid.Dialogs.Alerts.warn Katrid.i18n.gettext 'No pending changes'
    return

  findById: (id) ->
    for rec in @scope.records
      if rec.id is id
        return rec

  hasKey: (id) ->
    for rec in @scope.records
      if rec.id is id
        true

  validate: ->
    if @scope.form.$invalid
      s = "<span>#{Katrid.i18n.gettext 'The following fields are invalid:'}</span><hr>"
      el = @scope.formElement
      for errorType of @scope.form.$error
        for child in @scope.form.$error[errorType]
          elfield = el.find(""".form-field[name="#{child.$name}"]""")
          elfield.addClass('ng-touched')
          field = @scope.view.fields[child.$name]
          s += "<span>#{field.caption}</span><ul><li>#{Katrid.i18n.gettext 'This field cannot be empty.'}</li></ul>"
      console.log(elfield)
      elfield.focus()
      Katrid.Dialogs.Alerts.error s
      return false
    return true

  getIndex: (obj) ->
    rec = @findById(obj.id)
    @scope.records.indexOf(rec)

  search: (params, page) ->
    @_clearTimeout()
    @pendingRequest = true
    @loading = true
    page = page or 1
    @pageIndex = page
    params =
      count: true
      page: page
      params: params

    def = new $.Deferred()

    @pendingRequest = setTimeout =>
      @scope.model.search(params, {count: true})
      .fail (res) =>
        def.reject(res)
      .done (res) =>
        console.log(res)
        if @pageIndex > 1
          @offset = (@pageIndex - 1) * @pageLimit + 1
        else
          @offset = 1
        @.scope.$apply =>
          if res.result.count?
            @.recordCount = res.result.count
          @.scope.records = res.result.data
          if @pageIndex is 1
            @offsetLimit = @scope.records.length
          else
            @offsetLimit = @offset + @scope.records.length - 1
        def.resolve(res)
      .always =>
        @pendingRequest = false
        @scope.$apply =>
          @loading = false
    , @requestInterval

    return def.promise()

  goto: (index) ->
    @scope.moveBy(index - @recordIndex)

  moveBy: (index) ->
    newIndex = @recordIndex + index - 1
    if newIndex > -1 and newIndex < @scope.records.length
      @recordIndex = newIndex + 1
      @scope.location.search('id', @scope.records[newIndex].id)

  _clearTimeout: ->
    if @pendingRequest
      @loading = false
      @loadingRecord = false
      clearTimeout(@pendingRequest)

  setMasterSource: (master) ->
    @masterSource = master
    master.children.push(@)

  applyModifiedData: (form, element, record) ->
    data = @getModifiedData(form, element, record)
    if data
      ds = @modifiedData
      if not ds?
        ds = {}
      obj = ds[record]
      if not obj
        obj = {}
        ds[record] = obj
      for attr of data
        obj[attr] = data[attr]
        record[attr] = data[attr]

      @modifiedData = ds
      @masterSource.scope.form.$setDirty()
    return data

  getModifiedData: (form, element, record) ->
    if form.$dirty
      data = {}
      for el in $(element).find('.form-field.ng-dirty')
        nm = el.name
        data[nm] = record[nm]
      for child in @children
        subData = data[child.fieldName] or []
        for attr of child.modifiedData
          obj = child.modifiedData[attr]
          if obj.__state is RecordState.destroyed
            obj =
              action: 'DESTROY'
              id: obj.id
          else if obj.id
            obj =
              action: 'UPDATE'
              values: obj
          else
            obj =
              action: 'CREATE'
              values: obj
          subData.push(obj)
        if subData
          data[child.fieldName] = subData
      if data
        if record.id
          data.id = record.id
        return data
    return

  get: (id, timeout) ->
    @_clearTimeout()
    @setState(DataSourceState.loading)
    @loadingRecord = true
    def = new $.Deferred()

    _get = =>
      @scope.model.getById(id)
      .fail (res) =>
        def.reject(res)
      .done (res) =>
        @scope.$apply =>
          @_setRecord(res.result.data[0])
        def.resolve(res)
      .always =>
        @setState(DataSourceState.browsing)
        @scope.$apply =>
          @loadingRecord = false

    if timeout is 0
      return _get()
    if @requestInterval or timeout
      @pendingRequest = setTimeout _get, timeout or @requestInterval

    return def.promise()

  newRecord: ->
    @setState(DataSourceState.inserting)
    @scope.record = {}
    @scope.record.display_name = Katrid.i18n.gettext '(New)'
    @scope.model.getDefaults()
    .done (res) =>
      if res.result
        console.log('get defaults', res)
        @scope.$apply =>
          for attr, v of res.result
            console.log(attr, v)
            @scope.set(attr, v)

  editRecord: ->
    @setState(DataSourceState.editing)

  setState: (state) ->
    @state = state
    @changing =  @state in [DataSourceState.editing, DataSourceState.inserting]

  _setRecord: (rec) ->
    @scope.record = rec
    @scope.recordId = rec.id
    @state = DataSourceState.browsing

  next: ->
    @moveBy(1)

  prior: ->
    @moveBy(-1)

  nextPage: ->
    p = @recordCount / @pageLimit
    if Math.floor(p)
      p++
    if p > @pageIndex + 1
      @scope.location.search('page', @pageIndex + 1)

  prevPage: ->
    if @pageIndex > 1
      @scope.location.search('page', @pageIndex - 1)

  setRecordIndex: (index) ->
    @recordIndex = index + 1

  onFieldChange: (res) =>
    if res.ok and res.result.fields
      @scope.$apply =>
        for f, v of res.result.fields
          @scope.set(f, v)


class Record
  constructor: (@res) ->
    @data = @res.data


Katrid.Data =
  DataSource: DataSource
  Record: Record
  RecordState: RecordState
  DataSourceState: DataSourceState

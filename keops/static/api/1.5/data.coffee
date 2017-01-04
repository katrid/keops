
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

  cancelChanges: ->
    @scope.action.setViewType('list')

  saveChanges: ->
    # Submit fields with dirty state only
    el = $('[ng-form]').first()
    data = @getModifiedData(@scope.form, el, @scope.record)

    if data
      @uploading++
      @scope.model.write([data])
      .done =>
        @scope.form.$setPristine()
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
    @loadingRecord = true
    def = new $.Deferred()

    _get = =>
      @scope.model.get(id)
      .fail (res) =>
        def.reject(res)
      .done (res) =>
        @scope.$apply =>
          @_setRecord(res.result.data[0])
        def.resolve(res)
      .always =>
        @scope.$apply =>
          @loadingRecord = false

    if timeout is 0
      return _get()
    if @requestInterval or timeout
      @pendingRequest = setTimeout _get, timeout or @requestInterval

    return def.promise()

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


class Record
  constructor: (@res) ->
    @data = @res.data


Katrid.Data =
  DataSource: DataSource
  Record: Record
  RecordState: RecordState
  DataSourceState: DataSourceState

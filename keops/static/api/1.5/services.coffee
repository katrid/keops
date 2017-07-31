

class RequestManager
  constructor: ->
    @requestId = 0
    @requests = {}

  request: ->
    reqId = ++requestManager.requestId
    def = new $.Deferred()
    @requests[reqId] = def
    def.requestId = reqId
    return def


if Katrid.socketio
  console.log('socketio defined')
  requestManager = new RequestManager()

  Katrid.socketio.on 'connect', ->
    console.log("I'm connected!")

  Katrid.socketio.on 'api', (data) ->
    if _.isString(data)
      data = JSON.parse(data)
    def = requestManager.requests[data['req-id']]
    def.resolve(data)


class Service
  constructor: (@name) ->

  delete: (name, params, data) ->
  get: (name, params) ->
    if Katrid.Settings.servicesProtocol is 'ws'
      # Using websocket protocol
      Katrid.socketio.emit('api', { channel: 'rpc', service: @name, method: name, data: data, args: params })
    else
      # Using http/https protocol
      rpcName = Katrid.Settings.server + '/api/rpc/' + @name + '/' + name + '/'
      $.get(rpcName, params)

  post: (name, params, data) ->
    # Check if protocol is socket.io
    if Katrid.Settings.servicesProtocol is 'io'
      def = requestManager.request()
      Katrid.socketio.emit 'api',
        "req-id": def.requestId
        "req-method": 'POST'
        service: @name
        method: name
        data: data
        args: params
      return def

    # Else, using ajax
    else
      rpcName = Katrid.Settings.server + '/api/rpc/' + @name + '/' + name + '/'
      if params
        rpcName += '?' + $.param(params)
      return $.ajax
        method: 'POST'
        url: rpcName
        data: JSON.stringify(data)
        contentType: "application/json; charset=utf-8"
        dataType: 'json'


class Model extends Service
  searchName: (name) ->
    @post('search_name', { name: name })

  createName: (name) ->
    @post('create_name', null, { kwargs: { name: name } })

  search: (data, params) ->
    data = { kwargs: data }
    @post('search', params, data)

  destroy: (id) ->
    @post('destroy', null, { kwargs: { ids: [id] } })

  getById: (id) ->
    @post('get', null, { kwargs: { id: id } })

  getDefaults: (context) ->
    @post('get_defaults', null, { kwargs: { context: context } })

  copy: (id) ->
    @post('copy', null, { args: [id] })

  _prepareFields: (view) ->
    for f, v of view.fields
      # Add field display choices object
      if v.choices
        v.displayChoices = _.object(v.choices)

  getViewInfo: (data) ->
    @post('get_view_info', null, { kwargs: data })
    .done (res) =>
      @_prepareFields(res.result)

  loadViews: (data) ->
    @post('load_views', null, { kwargs: data })
    .done (res) =>
      for view, obj of res.result
        @_prepareFields(obj)

  getFieldChoices: (field, term) ->
    console.log('get field choices', field, term)
    @get('get_field_choices', { args: field, q: term })

  doViewAction: (data) ->
    @post('do_view_action', null, { kwargs: data })

  write: (data, params) ->
    @post('write', params, { kwargs: { data: data } })
    .done ->
      Katrid.Dialogs.Alerts.success Katrid.i18n.gettext 'Record saved successfully.'
    .fail (res) ->
      if res.status is 500 and res.responseText
        alert res.responseText
      else
        Katrid.Dialogs.Alerts.error Katrid.i18n.gettext 'Error saving record changes'

  groupBy: (grouping) ->
    @post('group_by', null, { kwargs: grouping })

  autoReport: ->
    @post 'auto_report', null, { kwargs: {} }

  onFieldChange: (field, record) ->
    @post('field_change', null, { kwargs: { field: field, record: record } })


@Katrid.Services =
  Service: Service
  Model: Model



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
    console.log('post', name, params, data)
    if Katrid.Settings.servicesProtocol is 'ws'
      Katrid.socketio.emit('api', { channel: 'rpc', service: @name, method: name, data: data, args: params })
    else
      rpcName = Katrid.Settings.server + '/api/rpc/' + @name + '/' + name + '/'
      if params
        rpcName += '?' + $.param(params)
      $.ajax
        method: 'POST'
        url: rpcName
        data: JSON.stringify(data)
        contentType: "application/json; charset=utf-8"
        dataType: 'json'


class Model extends Service
  searchName: (name) ->
    @post('search_name', { name: name })

  createName: (name) ->
    @post('create_name', null, { name: name })

  search: (data, params) ->
    data = { kwargs: data }
    @post('search', params, data)

  destroy: (id) ->
    @post('destroy', null, { kwargs: { ids: [id] } })

  getById: (id) ->
    @post('get', null, { kwargs: { id: id } })

  getDefaults: ->
    @post('get_defaults')

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

  onFieldChange: (field, record) ->
    @post('field_change', null, { kwargs: { field: field, record: record } })


@Katrid.Services =
  Service: Service
  Model: Model

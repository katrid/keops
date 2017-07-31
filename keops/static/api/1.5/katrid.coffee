
globals = @

@Katrid =
  Settings:
    server: ''
    servicesProtocol: if io? and io.connect then 'io' else 'http'

    # Katrid Framework UI Settings
    UI:
      dateInputMask: true
      defaultView: 'list'
      goToDefaultViewAfterCancelInsert: true
      goToDefaultViewAfterCancelEdit: false
      horizontalForms: true

    Services:
      choicesPageLimit: 10

    Speech:
      enabled: false

  Bootstrap:
    additionalModules: []

  # Internationalization
  i18n:
    languageCode: 'pt-BR'
    formats: {}
    catalog: {}

    initialize: (plural, catalog, formats) ->
      Katrid.i18n.plural = plural
      Katrid.i18n.catalog = catalog
      Katrid.i18n.formats = formats
      if plural
        Katrid.i18n.pluralidx = (n) ->
          if plural instanceof boolean
            return if plural then 1 else 0
          else
            return plural
      else
        Katrid.i18n.pluralidx = (n) ->
          return if count is 1 then 0 else 1

      globals.pluralidx = Katrid.i18n.pluralidx
      globals.gettext = Katrid.i18n.gettext
      globals.ngettext = Katrid.i18n.ngettext
      globals.gettext_noop = Katrid.i18n.gettext_noop
      globals.pgettext = Katrid.i18n.pgettext
      globals.npgettext = Katrid.i18n.npgettext
      globals.interpolate = Katrid.i18n.interpolate
      globals.get_format = Katrid.i18n.get_format

      Katrid.i18n.initialized = true

    merge: (catalog) ->
      for key in catalog
        Katrid.i18n.catalog[key] = catalog[key]

    gettext: (s) ->
      value = Katrid.i18n.catalog[s]
      if value?
        value
      else
        s

    gettext_noop: (s) -> s

    ngettext: (singular, plural, count) ->
      value = Katrid.i18n.catalog[singular]
      if value?
        value[Katrid.i18n.pluralidx(count)]
      else if count is 1
        singular
      else
        plural

    pgettext: (s) ->
      value = Katrid.i18n.gettext(s)
      if value.indexOf('\x04') isnt -1
        value = s
      value

    npgettext: (ctx, singular, plural, count) ->
      value = Katrid.i18n.ngettext(ctx + '\x04' + singular, ctx + '\x04' + plural, count)
      if value.indexOf('\x04') isnt -1
        value = Katrid.i18n.ngettext(singular, plural, count)
      value

    interpolate: (fmt, obj, named) ->
      if named
        fmt.replace(/%\(\w+\)s/g, (match) -> String(obj[match.slice(2,-2)]))
      else
        fmt.replace(/%s/g, (match) -> String(obj.shift()))

      get_format: (formatType) ->
        value = Katrid.i18n.formats[formatType]
        if value?
          value
        else
          formatType

if Katrid.Settings.servicesProtocol is 'io'
  Katrid.socketio = io.connect('//' + document.domain + ':' + location.port + '/rpc')

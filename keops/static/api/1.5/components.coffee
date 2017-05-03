uiKatrid = Katrid.uiKatrid

formCount = 0

uiKatrid.directive 'field', ($compile) ->
  fieldType = null
  widget = null
  restrict: 'E'
  replace: true
  #transclude: true
#  template: (element, attrs) ->
#    if (element.parent('list').length)
#      fieldType = 'column'
#      return '<column/>'
#    else
#      fieldType = 'field'
#      return """<section class="section-field-#{attrs.name} form-group" />"""

  link: (scope, element, attrs, ctrl, transclude) ->
    field = scope.view.fields[attrs.name]

    if element.parent('list').length is 0
      element.removeAttr('name')
      widget = attrs.widget
      if widget
        console.log(widget)
      if not widget
        tp = field.type
        if tp is 'ForeignKey'
          widget = tp
        else if field.choices
          widget = 'SelectField'
        else if tp is 'TextField'
          widget = 'TextareaField'
        else if tp is 'BooleanField'
          widget = 'CheckBox'
          cols = 3
        else if tp is 'DecimalField'
          widget = 'DecimalField'
          cols = 3
        else if tp is 'DateField'
          widget = 'DateField'
          cols = 3
        else if tp is 'DateTimeField'
          widget = 'DateField'
          cols = 3
        else if tp is 'IntegerField'
          widget = 'TextField'
          cols = 3
        else if tp is 'SmallIntegerField'
          widget = 'TextField'
          cols = 3
        else if tp is 'CharField'
          widget = 'TextField'
          if field.max_length and field.max_length < 30
            cols = 3
        else if tp is 'OneToManyField'
          widget = tp
          cols = 12
        else if tp is 'ManyToManyField'
          widget = tp
        else if tp is 'FileField'
          console.log('file field')
          widget = tp
        else
          widget = 'TextField'

      widget = new Katrid.UI.Widgets[widget]()
      field = scope.view.fields[attrs.name]

      templAttrs = []
      if attrs.ngShow
        templAttrs.push(' ng-show="' + attrs.ngShow + '"')
      templAttrs = templAttrs.join(' ')

      templTag = 'section'

      templ = """<#{templTag} class="section-field-#{attrs.name} form-group" #{templAttrs}>""" +
        widget.template(scope, element, attrs, field) +
        '</#{templTag}>'
      templ = $compile(templ)(scope)
      element.replaceWith(templ)
      templ.addClass("col-md-#{attrs.cols or cols or 6}")

      # Add input field for tracking on FormController
      fcontrol = templ.find('.form-field')
      if fcontrol.length
        fcontrol = fcontrol[fcontrol.length - 1]
        form = templ.controller('form')
        ctrl = angular.element(fcontrol).data().$ngModelController
        if ctrl
          form.$addControl(ctrl)

      #templ.find('.field').addClass("col-md-#{attrs.cols or cols or 6}")

      widget.link(scope, templ, fieldAttrs, $compile, field)

      # Remove field attrs from section element
      fieldAttrs = {}
      for att, v of attrs when att.startsWith('field')
        fieldAttrs[att] = v
        element.removeAttr(att)
        attrs.$set(att)

      fieldAttrs.name = attrs.name


uiKatrid.directive 'view', ->
  restrict: 'E'
  template: (element, attrs) ->
    formCount++
    ''
  link: (scope, element, attrs) ->
    if scope.model
      element.attr('class', 'view-form-' + scope.model.name.replace(new RegExp('\.', 'g'), '-'))
      element.attr('id', 'katrid-form-' + formCount.toString())
      element.attr('model', scope.model)
      element.attr('name', 'dataForm' + formCount.toString())


uiKatrid.directive 'list', ($compile, $http) ->
  restrict: 'E'
  priority: 700
  link: (scope, element, attrs) ->
    console.log('im list', 1)
    html = Katrid.UI.Utils.Templates.renderList(scope, element, attrs)
    element.replaceWith($compile(html)(scope))


uiKatrid.directive 'ngSum', ->
  restrict: 'A'
  priority: 9999
  require: 'ngModel'
  link: (scope, element, attrs, controller) ->
    nm = attrs.ngSum.split('.')
    field = nm[0]
    subField = nm[1]
    scope.$watch 'record.$' + field, (newValue, oldValue) ->
      if newValue and scope.record
        v = 0
        scope.record[field].map (obj) => v += parseFloat(obj[subField])
        if v.toString() != controller.$modelValue
          controller.$setViewValue v
          controller.$render()
        return


uiKatrid.directive 'grid', ($compile) ->
  restrict: 'E'
  replace: true
  scope: {}
  link: (scope, element, attrs) ->
    # Load remote field model info
    field = scope.$parent.view.fields[attrs.name]
    scope.action = scope.$parent.action
    scope.fieldName = attrs.name
    scope.field = field
    scope.records = []
    scope.recordIndex = -1
    scope._cachedViews = {}
    scope._changeCount = 0
    scope.dataSet = []
    scope.parent = scope.$parent
    scope.model = new Katrid.Services.Model(field.model)

    # Set parent/master data source
    scope.dataSource = new Katrid.Data.DataSource(scope)
    p = scope.$parent
    while p
      if p.dataSource
        scope.dataSource.setMasterSource(p.dataSource)
        break
      p = p.$parent

    scope.dataSource.fieldName = scope.fieldName
    scope.gridDialog = null
    scope.model.loadViews()
    .done (res) ->
      scope.$apply ->
        scope._cachedViews = res.result
        console.log(res.result)
        scope.view = scope._cachedViews.list
        html = Katrid.UI.Utils.Templates.renderGrid(scope, $(scope.view.content), attrs, 'openItem($index)')
        element.replaceWith($compile(html)(scope))

    renderDialog = ->
      html = scope._cachedViews.form.content
      html = $(Katrid.UI.Utils.Templates.gridDialog().replace('<!-- view content -->', html))
      el = $compile(html)(scope)

      # Get the first form controller
      scope.formElement = el.find('form').first()
      scope.form = scope.formElement.controller('form')

      scope.gridDialog = el
      el.modal('show')
      el.on 'hidden.bs.modal', ->
        scope.dataSource.setState(Katrid.Data.DataSourceState.browsing)
        el.remove()
        scope.gridDialog = null
        scope.recordIndex = -1
      return false

    scope.doViewAction = (viewAction, target, confirmation) ->
      return scope.action._doViewAction(scope, viewAction, target, confirmation)

    scope._incChanges = ->
      scope.parent.record['$' + scope.fieldName] = ++scope._changeCount
      scope.parent.record[scope.fieldName] = scope.records

    scope.addItem = ->
      scope.dataSource.newRecord()
      scope.showDialog()

    scope.openItem = (index) ->
      scope.showDialog(index)
      if scope.parent.dataSource.changing
        scope.dataSource.editRecord()

    scope.removeItem = (idx) ->
      rec = scope.records[idx]
      scope.records.splice(idx, 1)
      scope._incChanges()
      rec.$deleted = true
      scope.dataSource.applyModifiedData(null, null, rec)

    scope.$set = (field, value) =>
      control = scope.form[field]
      control.$setViewValue value
      control.$render()
      return

    scope.save = ->
      data = scope.dataSource.applyModifiedData(scope.form, scope.gridDialog, scope.record)
      if scope.recordIndex > -1
        rec = scope.records[scope.recordIndex]
        for attr, v of data
          rec[attr] = v
      else if scope.recordIndex is -1
        scope.records.push(scope.record)
      scope.gridDialog.modal('toggle')
      scope._incChanges()
      return

    scope.showDialog = (index) ->
      if index?
        # Show item dialog
        scope.recordIndex = index

        if not scope.dataSet[index]
          scope.dataSource.get(scope.records[index].id, 0)
          .done (res) ->
            if res.ok
              scope.$apply ->
                scope.dataSet[index] = scope.record
                if scope.parent.dataSource.changing
                  scope.dataSource.editRecord()
        rec = scope.dataSet[index]
        scope.record = rec
      else
        scope.recordIndex = -1

      if scope._cachedViews.form
        setTimeout ->
          renderDialog()
      else
        scope.model.getViewInfo({ view_type: 'form' })
        .done (res) ->
          if res.ok
            scope._cachedViews.form = res.result
            renderDialog()

      return

    masterChanged = (key) ->
      # Ajax load nested data
      data = {}
      data[field.field] = key
      scope._changeCount = 0
      scope.records = []
      scope.dataSource.search(data)

    scope.$parent.$watch 'recordId', (key) ->
      masterChanged(key)


uiKatrid.directive 'ngEnter', ->
  (scope, element, attrs) ->
    element.bind "keydown keypress", (event) ->
      if event.which is 13
        scope.$apply ->
          scope.$eval(attrs.ngEnter)

        event.preventDefault()


uiKatrid.directive 'datepicker', ['$filter', ($filter) ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, element, attrs, controller) ->
    el = element
    dateFmt = Katrid.i18n.gettext 'yyyy-mm-dd'
    shortDate = dateFmt.replace(/[m]/g, 'M')
    calendar = element.parent('div').datepicker
      format: dateFmt
      keyboardNavigation: false
      language: Katrid.i18n.languageCode
      forceParse: false
      autoClose: true
      showOnFocus: false
    .on 'changeDate', (e) ->
      dp = calendar.data('datepicker')
      if dp.picker.is(':visible')
        el.val($filter('date')(dp._utc_to_local(dp.viewDate), shortDate))
        dp.hide()

    # Mask date format
    if Katrid.Settings.UI.dateInputMask is true
      el = el.mask(dateFmt.replace(/[A-z]/g, 0))
    else if Katrid.Settings.UI.dateInputMask
      el = el.mask(Katrid.Settings.UI.dateInputMask)

    controller.$formatters.push (value) ->
      dt = new Date(value)
      calendar.datepicker('setDate', dt)
      return $filter('date')(value, shortDate)

    controller.$parsers.push (value) ->
      console.log('parsers', value, controller)
      return moment.utc(value, shortDate.toUpperCase()).format('YYYY-MM-DD')

    el.on 'blur', (evt) ->
      dp = calendar.data('datepicker')
      if dp.picker.is(':visible')
        dp.hide()
      if '/' in Katrid.i18n.formats.SHORT_DATE_FORMAT
        sep = '/'
      else
        sep = '-'
      fmt = Katrid.i18n.formats.SHORT_DATE_FORMAT.toLowerCase().split(sep)
      dt = new Date()
      s = el.val()
      if fmt[0] is 'd' and fmt[1] is 'm'
        if (s.length is 5) or (s.length is 6)
          if s.length is 6
            s = s.substr(0, 5)
          val = s + sep + dt.getFullYear().toString()
        if (s.length is 2) or (s.length is 3)
          if s.length is 3
            s = s.substr(0, 2)
          val = new Date(dt.getFullYear(), dt.getMonth(), s)
      else if fmt[0] is 'm' and fmt[1] is 'd'
        if (s.length is 5) or (s.length is 6)
          if s.length is 6
            s = s.substr(0, 5)
          val = s + sep + dt.getFullYear().toString()
        if (s.length is 2) or (s.length is 3)
          if s.length is 3
            s = s.substr(0, 2)
          val = new Date(dt.getFullYear(), s, dt.getDay())
      if val
        calendar.datepicker('setDate', val)
        el.val($filter('date')(dp._utc_to_local(dp.viewDate), shortDate))
        controller.$setViewValue($filter('date')(dp._utc_to_local(dp.viewDate), shortDate))
]

uiKatrid.directive 'ajaxChoices', ($location) ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, element, attrs, controller) ->
    multiple = attrs.multiple
    serviceName = attrs.ajaxChoices
    cfg =
      ajax:
        url: serviceName
        dataType: 'json'
        quietMillis: 500
        data: (term, page) ->
          q: term,
          count: 1,
          page: page - 1
          #file: attrs.reportFile
          field: attrs.field
        results: (data, page) ->
          res = data.result
          data = res.items
          more = (page * Katrid.Settings.Services.choicesPageLimit) < res.count
          #if not multiple and (page is 1)
          #  data.splice(0, 0, {id: null, text: '---------'})
          results: ({ id: item[0], text: item[1] } for item in data)
          more: more
      escapeMarkup: (m) ->
        m
      initSelection: (element, callback) ->
        v = controller.$modelValue
        if v
          if multiple
            values = []
            for i in v
              values.push({id: i[0], text: i[1]})
            callback(values)
          else
            callback({id: v[0], text: v[1]})
    if multiple
      cfg['multiple'] = true
    el = element.select2(cfg)
    element.on '$destroy', ->
      $('.select2-hidden-accessible').remove()
      $('.select2-drop').remove()
      $('.select2-drop-mask').remove()
    el.on 'change', (e) ->
      v = el.select2('data')
      controller.$setDirty()
      if v
        controller.$viewValue = v
      scope.$apply()

    controller.$render = ->
      if (controller.$viewValue)
        element.select2('val', controller.$viewValue)


uiKatrid.directive 'decimal', ($filter) ->
  restrict: 'A',
  require: 'ngModel',
  link: (scope, element, attrs, controller) ->

    precision = parseInt(attrs.precision) or 2

    thousands = attrs.uiMoneyThousands or "."
    decimal = attrs.uiMoneyDecimal or ","
    symbol = attrs.uiMoneySymbol
    negative = attrs.uiMoneyNegative or true
    el = element.maskMoney
      symbol: symbol
      thousands: thousands
      decimal: decimal
      precision: precision
      allowNegative: negative
      allowZero: true
    .bind 'keyup blur', (event) ->
      newVal = element.maskMoney('unmasked')[0]
      if newVal.toString() != controller.$viewValue
        controller.$setViewValue(newVal)
        scope.$apply()

    controller.$render = ->
      if controller.$viewValue
        element.val($filter('number')(controller.$viewValue, precision))
      else
        element.val('')


Katrid.uiKatrid.directive 'foreignkey', ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, el, attrs, controller) ->

    #f = scope.view.fields['model']
    sel = el

    el.addClass 'form-field'

    if attrs.serviceName
      serviceName = attrs.serviceName
    else
      serviceName = scope.model.name

    newItem = ->

    config =
      allowClear: true
      ajax:
        url: '/api/rpc/' + serviceName + '/get_field_choices/?args=' + attrs.name

        data: (term, page) ->
          count: 1
          page: page - 1
          q: term

        results: (data, page) ->
          console.log('load page', page, data)
          res = data.result
          data = res.items
          r = ({ id: item[0], text: item[1] } for item in data)
          more = (page * Katrid.Settings.Services.choicesPageLimit) < res.count
          if not multiple and not more
            msg = Katrid.i18n.gettext('Create <i>"{0}"</i>...')
            if sel.data('select2').search.val()
              r.push
                id: newItem
                text: msg
          results: r
          more: more

      formatResult: (state) ->
        s = sel.data('select2').search.val()
        if state.id is newItem
          state.str = s
          return '<strong>' + state.text.format(s) + '</strong>'
        return state.text

      initSelection: (el, cb) ->
        v = controller.$modelValue
        if multiple
          v = ({id: obj[0], text: obj[1]} for obj in v)
          cb(v)
        else if v
          cb({id: v[0], text: v[1]})

    multiple = attrs.multiple

    if multiple
      config['multiple'] = true

    sel = sel.select2(config)

    sel.on 'change', (e) ->
      v = sel.select2('data')
      if v.id is newItem
        service = new Katrid.Services.Model(scope.view.fields[attrs.name].model)
        service.createName(v.str)
        .then (res) ->
          controller.$setDirty()
          controller.$setViewValue res.result
          sel.select2('val', {id: res.result[0], text: res.result[1]})
      else if v and multiple
        v = (obj.id for obj in v)
        controller.$setViewValue v
      else
        controller.$setDirty()
        if v
          controller.$setViewValue [v.id, v.text]
        else
          controller.$setViewValue null

    scope.$watch attrs.ngModel, (newValue, oldValue) ->
      sel.select2('val', newValue)

    controller.$render = ->
      if multiple
        if controller.$viewValue
          v = (obj[0] for obj in controller.$viewValue)
          sel.select2('val', v)
      if controller.$viewValue
        sel.select2('val', controller.$viewValue[0])
      else
        sel.select2('val', null)


uiKatrid.directive 'searchView', ($compile) ->
  restrict: 'E'
  #require: 'ngModel'
  replace: true
  link: (scope, el, attrs, controller) ->
    scope.search = {}
    widget = new Katrid.UI.Views.SearchView(scope, {})
    widget.link(scope, el, attrs, controller, $compile)
    return


uiKatrid.directive 'searchBox', ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, el, attrs, controller) ->
    view = scope.views.search
    fields = view.fields

    cfg =
      multiple: true
      minimumInputLength: 1
      formatSelection: (obj, element) =>
        if obj.field
          element.append("""<span class="search-icon">#{obj.field.caption}</span>: <i class="search-term">#{obj.text}</i>""")
        else if obj.id.caption
          element.append("""<span class="search-icon">#{obj.id.caption}</span>: <i class="search-term">#{obj.text}</i>""")
        else
          element.append('<span class="fa fa-filter search-icon"></span><span class="search-term">' + obj.text + '</span>')
        return

      id: (obj) ->
        if obj.field
          return obj.field.name
          return '<' + obj.field.name + ' ' + obj.id + '>'
        return obj.id.name
        return obj.id.name + '-' + obj.text

      formatResult: (obj, element, query) =>
        if obj.id.type is 'ForeignKey'
          return """> Pesquisar <i>#{obj.id.caption}</i> por: <strong>#{obj.text}</strong>"""
        else if obj.field and obj.field.type is 'ForeignKey'
          return """#{obj.field.caption}: <i>#{obj.text}</i>"""
        else
          return """Pesquisar <i>#{obj.id.caption}</i> por: <strong>#{obj.text}</strong>"""

      query: (options) =>
        if options.field
          scope.model.getFieldChoices(options.field.name, options.term)
          .done (res) ->
            options.callback
              results: ({ id: obj[0], text: obj[1], field: options.field } for obj in res.result)
          return

        options.callback
          results: ({ id: fields[f], text: options.term } for f of fields)
        return

    el.select2(cfg)
    el.data('select2').blur()
    el.on 'change', =>
      controller.$setViewValue(el.select2('data'))

    el.on 'select2-selecting', (e) =>
      if e.choice.id.type is 'ForeignKey'
        v = el.data('select2')
        v.opts.query
          element: v.opts.element
          term: v.search.val()
          field: e.choice.id
          callback: (data) ->
            v.opts.populateResults.call(v, v.results, data.results, {term: '', page: null, context:v.context})
            v.postprocessResults(data, false, false)

        e.preventDefault()

    return

uiKatrid.controller 'TabsetController', [
  '$scope'
  ($scope) ->
    ctrl = this
    tabs = ctrl.tabs = $scope.tabs = []

    ctrl.select = (selectedTab) ->
      angular.forEach tabs, (tab) ->
        if tab.active and tab != selectedTab
          tab.active = false
          tab.onDeselect()
        return
      selectedTab.active = true
      selectedTab.onSelect()
      return

    ctrl.addTab = (tab) ->
      tabs.push tab
      # we can't run the select function on the first tab
      # since that would select it twice
      if tabs.length == 1
        tab.active = true
      else if tab.active
        ctrl.select tab
      return

    ctrl.removeTab = (tab) ->
      index = tabs.indexOf(tab)
      #Select a new tab if the tab to be removed is selected and not destroyed
      if tab.active and tabs.length > 1 and !destroyed
        #If this is the last tab, select the previous tab. else, the next tab.
        newActiveIndex = if index == tabs.length - 1 then index - 1 else index + 1
        ctrl.select tabs[newActiveIndex]
      tabs.splice index, 1
      return

    destroyed = undefined
    $scope.$on '$destroy', ->
      destroyed = true
      return
    return
]

uiKatrid.directive 'tabset', ->
  restrict: 'EA'
  transclude: true
  replace: true
  scope:
    type: '@'
  controller: 'TabsetController',
  template: "<div><div class=\"clearfix\"></div>\n" +
            "  <ul class=\"nav nav-{{type || 'tabs'}}\" ng-class=\"{'nav-stacked': vertical, 'nav-justified': justified}\" ng-transclude></ul>\n" +
            "  <div class=\"tab-content\">\n" +
            "    <div class=\"tab-pane\" \n" +
            "         ng-repeat=\"tab in tabs\" \n" +
            "         ng-class=\"{active: tab.active}\"\n" +
            "         tab-content-transclude=\"tab\">\n" +
            "    </div>\n" +
            "  </div>\n" +
            "</div>\n"
  link: (scope, element, attrs) ->
    scope.vertical = if angular.isDefined(attrs.vertical) then scope.$parent.$eval(attrs.vertical) else false
    scope.justified = if angular.isDefined(attrs.justified) then scope.$parent.$eval(attrs.justified) else false


uiKatrid.directive 'tab', [
  '$parse'
  ($parse) ->
    {
      require: '^tabset'
      restrict: 'EA'
      replace: true
      template: "<li ng-class=\"{active: active, disabled: disabled}\">\n" +
          "  <a href ng-click=\"select()\" tab-heading-transclude>{{heading}}</a>\n" +
          "</li>\n"
      transclude: true
      scope:
        active: '=?'
        heading: '@'
        onSelect: '&select'
        onDeselect: '&deselect'
      controller: ->
        #Empty controller so other directives can require being 'under' a tab
        return
      compile: (elm, attrs, transclude) ->
        (scope, elm, attrs, tabsetCtrl) ->
          scope.$watch 'active', (active) ->
            if active
              tabsetCtrl.select scope
            return
          scope.disabled = false
          if attrs.disabled
            scope.$parent.$watch $parse(attrs.disabled), (value) ->
              scope.disabled = ! !value
              return

          scope.select = ->
            if !scope.disabled
              scope.active = true
            return

          tabsetCtrl.addTab scope
          scope.$on '$destroy', ->
            tabsetCtrl.removeTab scope
            return
          #We need to transclude later, once the content container is ready.
          #when this link happens, we're inside a tab heading.
          scope.$transcludeFn = transclude
          return

    }
]

uiKatrid.directive 'tabHeadingTransclude', [ ->
  {
    restrict: 'A'
    require: '^tab'
    link: (scope, elm, attrs, tabCtrl) ->
      scope.$watch 'headingElement', (heading) ->
        if heading
          elm.html ''
          elm.append heading
        return
      return

  }
 ]


uiKatrid.directive 'tabContentTransclude', ->

  isTabHeading = (node) ->
    node.tagName and (node.hasAttribute('tab-heading') or node.hasAttribute('data-tab-heading') or node.tagName.toLowerCase() == 'tab-heading' or node.tagName.toLowerCase() == 'data-tab-heading')

  {
    restrict: 'A'
    require: '^tabset'
    link: (scope, elm, attrs) ->
      tab = scope.$eval(attrs.tabContentTransclude)
      #Now our tab is ready to be transcluded: both the tab heading area
      #and the tab content area are loaded.  Transclude 'em both.
      tab.$transcludeFn tab.$parent, (contents) ->
        angular.forEach contents, (node) ->
          if isTabHeading(node)
            #Let tabHeadingTransclude know.
            tab.headingElement = node
          else
            elm.append node
          return
        return
      return

  }


uiKatrid.filter 'm2m', ->
  return (input) ->
    if _.isArray input
      return (obj[1] for obj in input).join(', ')


uiKatrid.filter 'moment', ->
  return (input, format) ->
    if format
      return moment().format(format)
    return moment(input).fromNow()


uiKatrid.directive 'fileReader', ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attrs, controller) ->
    console.log('link file read')
    element.bind 'change', ->
      reader = new FileReader()
      reader.onload = (event) ->
        controller.$setViewValue event.target.result
      reader.readAsDataURL(event.target.files[0])


uiKatrid = Katrid.uiKatrid

formCount = 0

uiKatrid.directive 'field', ($compile) ->
  fieldType = null
  widget = null
  restrict: 'E'
  replace: true
  transclude: false
  template: (element, attrs) ->
    if (element.parent('list').length)
      fieldType = 'column'
      return '<column></column>'
    else
      fieldType = 'field'
      return """<section class="section-field-#{attrs.name} form-group" />"""

  link: (scope, element, attrs) ->
    field = scope.view.fields[attrs.name]

    if fieldType == 'field'
      element.removeAttr('name')
      widget = attrs.widget
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
        else if tp is 'DecimalField'
          widget = 'DecimalField'
          cols = 3
        else if tp is 'IntegerField'
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
        else
          widget = 'TextField'

      element.addClass("col-md-#{attrs.cols or cols or 6}")
      widget = new Katrid.UI.Widgets[widget]
      field = scope.view.fields[attrs.name]
      templ = $compile(widget.template(scope, element, attrs, field))(scope)
      element.append(templ)

      # Add input field for tracking on FormController
      fcontrol = templ.find('.form-field')
      if fcontrol.length
        fcontrol = fcontrol[fcontrol.length - 1]
        form = element.controller('form')
        ctrl = angular.element(fcontrol).data().$ngModelController
        if ctrl
          form.$addControl(ctrl)

      widget.link(scope, element, attrs, $compile, field)


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
  link: (scope, element, attrs) ->
    html = Katrid.UI.Utils.Templates.renderList(scope, element, attrs)
    element.replaceWith($compile(html)(scope))


uiKatrid.controller 'dialogForm', ($scope) ->
  console.log('start controller')
  $scope.form


uiKatrid.directive 'grid', ($compile, $http) ->
  restrict: 'E'
  replace: true
  scope: {}
  link: (scope, element, attrs) ->
    # Load remote field model info
    field = scope.$parent.view.fields[attrs.name]
    scope.fieldName = attrs.name
    scope.field = field
    scope.records = []
    scope.recordIndex = -1
    scope._viewCache = {}
    scope.dataSet = []
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
    scope.model.getViewInfo({ view_type: 'list' })
    .done (res) ->
      scope.$apply ->
        scope.view = res.result
        html = Katrid.UI.Utils.Templates.renderGrid(scope, $(scope.view.content), attrs, 'showDialog($index)')
        element.replaceWith($compile(html)(scope))

    renderDialog = ->
      html = scope._viewCache.form.content
      html = $(Katrid.UI.Utils.Templates.gridDialog().replace('<!-- view content -->', html))
      el = $compile(html)(scope)
      scope.gridDialog = el
      el.modal('show')
      el.on 'hidden.bs.modal', ->
        el.remove()
        scope.gridDialog = null
        scope.recordIndex = -1
      return false

    scope.addItem = ->
      scope.showDialog()

    scope.save = ->
      data = scope.dataSource.applyModifiedData(scope.form, scope.gridDialog, scope.record)
      if scope.recordIndex > -1
        rec = scope.records[scope.recordIndex]
        for attr of data
          rec[attr] = data[attr]
      scope.gridDialog.modal('toggle')
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
        rec = scope.dataSet[index]
      else
        scope.recordIndex = -1
        rec = {}

      scope.record = rec

      if scope._viewCache.form
        setTimeout ->
          renderDialog()
      else
        scope.model.getViewInfo({ view_type: 'form' })
        .done (res) ->
          if res.ok
            scope._viewCache.form = res.result
            renderDialog()

      return false

    masterChanged = (key) ->
      # Ajax load nested data
      data = {}
      data[field.field] = key
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



uiKatrid.directive 'datepicker', ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, element, attrs, controller) ->
    el = element.datepicker
      format: Katrid.i18n.gettext 'dd/mm/yyyy'
      forceParse: false

    updateModelValue = ->
      el.val(controller.$modelValue)

    scope.$watch(attrs.ngModel, updateModelValue)

    el = el.mask('00/00/0000')

    controller.$render = ->
      console.log(controller.$modelValue)

    el.on 'blur', (evt) ->
      s = el.val()
      if (s.length is 5) or (s.length is 6)
        if s.length is 6
          s = s.substr(0, 5)
        dt = new Date()
        el.datepicker('setDate', s + '/' + dt.getFullYear().toString())
      if (s.length is 2) or (s.length is 3)
        if s.length is 3
          s = s.substr(0, 2)
        dt = new Date()
        el.datepicker('setDate', new Date(dt.getFullYear(), dt.getMonth(), s))


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
          t: 1,
          p: page - 1
          file: attrs.reportFile
          sql_choices: attrs.sqlChoices
        results: (data, page) ->
          console.log(data)
          data = data.items
          more = (page * 10) < data.count
          if not multiple and (page is 1)
            data.splice(0, 0, {id: null, text: '---------'})
          results: data
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

    precision = attrs.precision or 2

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
      controller.$setViewValue(element.val().replace(RegExp('\\' + thousands, 'g'), '').replace(RegExp('\\' + decimal, 'g'), '.'))
      controller.$modelValue = parseFloat(element.val().replace(RegExp('\\' + thousands, 'g'), '').replace(RegExp('\\' + decimal, 'g'), '.'))
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

    f = scope.view.fields['model']
    sel = el

    el.addClass 'form-field'

    newItem = () ->

    config =
      allowClear: true
      ajax:
        url: '/api/rpc/' + scope.model.name + '/get_field_choices/?args=' + attrs.name

        data: (term, page) ->
          q: term

        results: (data, page) ->
          r = ({id: item[0], text: item[1]} for item in data.result)
          if not multiple
            msg = Katrid.i18n.gettext('Create <i>"{0}"</i>...')
            if sel.data('select2').search.val()
              r.push({id: newItem, text: msg})
          results: r

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

    controller.$render = ->
      if multiple
        if controller.$viewValue
          v = (obj[0] for obj in controller.$viewValue)
          sel.select2('val', v)
      if controller.$viewValue
        sel.select2('val', controller.$viewValue[0])
      else
        sel.select2('val', null)


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
  template: "<div>\n" +
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


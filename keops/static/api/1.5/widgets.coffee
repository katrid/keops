widgetCount = 0


class Widget
  tag: 'div'
  constructor: ->
    @classes = ['form-field']

  ngModel: (attrs) ->
    'record.' + attrs.name

  getId: (id) ->
    return 'katrid-input-' + id.toString()

  getWidgetAttrs: (scope, el, attrs, field) ->
    html = ''
    if field.required
      html = ' required'
    html += ' ng-model="' + @ngModel(attrs) + '"'
    for attr of attrs
      if attr.startsWith('fieldNg')
        attrName = attr.substr(7, attr.length - 7)
        html += """ ng-#{attrName}="#{attrs[attr]}" """
    classes = ''
    for cls in @classes
      classes += ' ' + cls
    if classes
      html += ' class="' + classes + '"'
    return html

  template: (scope, el, attrs, field, type='text') ->
    widgetCount++
    id = @getId(widgetCount)
    html = '<' +
      @tag + ' id="' + id +
      '" type="' + type + '" name="' + attrs.name +
      '" ' + @getWidgetAttrs(scope, el, attrs, field) +
      '>'
    attrs._id = id
    return html

  link: (scope, el, attrs, $compile, field) ->


class InputWidget extends Widget
  tag: 'input'
  constructor: ->
    super
    @classes.push('form-control')


class TextField extends InputWidget
  getWidgetAttrs: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field)
    if field.max_length
      html += ' maxlength="' + field.max_length.toString() + '"'
    return html

  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field)
    html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>'
    return html


class SelectField extends InputWidget
  tag: 'select'

  template: (scope, el, attrs, field) ->
    widgetCount++
    id = @getId(widgetCount)
    html = '<' +
      @tag + ' id="' + id + '" name="' + attrs.name +
      '" ' + @getWidgetAttrs(scope, el, attrs, field) +
      '>' +
      '<option ng-repeat="choice in view.fields.' + attrs.name + '.choices" value="${choice[0]}">${choice[1]}</option>' +
      '>'
    attrs._id = id

    html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>'
    return html



class ForeignKey extends Widget
  tag: 'input foreignkey'
  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'hidden')
    html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>'
    return html


class TextareaField extends TextField
  tag: 'textarea'


class DecimalField extends TextField
  tag: 'input decimal'

class OneToManyField extends Widget
  tag: 'grid'

  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'grid')
    return html


class CheckBox extends InputWidget
  constructor: ->
    super
    @classes = []

  getWidgetAttrs: (scope, el, attrs, field) ->
    html = ''
    html += ' ng-model="' + @ngModel(attrs) + '"'
    classes = ''
    for cls in @classes
      classes += ' ' + cls
    if classes
      html += ' class="' + classes + '"'
    return html

  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'checkbox')
    s = '<div>'
    if field.help_text
      s += '<label for="' + attrs._id + '">' + field.caption + '</label>'
    html = s + '<div class="checkbox"><label>' + html
    if field.help_text
      html += field.help_text
    else
      html += field.caption
    html += '</label></div></div>'
    return html


Katrid.uiKatrid.directive 'foreignkey', ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, el, attrs, controller) ->

    f = scope.view.fields['model']
    sel = el

    newItem = () ->

    config =
      allowClear: true
      ajax:
        url: '/api/rpc/' + scope.model.name + '/get_field_choices/?args=' + attrs.name

        data: (term, page) ->
          q: term

        results: (data, page) ->
          msg = Katrid.i18n.gettext('Create <i>"{0}"</i>...')
          r = ({id: item[0], text: item[1]} for item in data.result)
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
        if v
          cb({id: v[0], text: v[1]})


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
      else
        controller.$setDirty()
        if v
          controller.$setViewValue [v.id, v.text]
        else
          controller.$setViewValue null

    controller.$render = ->
      if controller.$viewValue
        sel.select2('val', controller.$viewValue[0])
      else
        sel.select2('val', null)


@Katrid.UI.Widgets =
  Widget: Widget
  InputWidget: InputWidget
  TextField: TextField
  SelectField: SelectField
  ForeignKey: ForeignKey
  TextareaField: TextareaField
  DecimalField: DecimalField
  OneToManyField: OneToManyField
  CheckBox: CheckBox

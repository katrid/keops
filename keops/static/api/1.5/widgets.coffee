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


class ManyToManyField extends Widget
  tag: 'input foreignkey multiple'

  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'hidden')
    html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>'
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


@Katrid.UI.Widgets =
  Widget: Widget
  InputWidget: InputWidget
  TextField: TextField
  SelectField: SelectField
  ForeignKey: ForeignKey
  TextareaField: TextareaField
  DecimalField: DecimalField
  CheckBox: CheckBox
  OneToManyField: OneToManyField
  ManyToManyField: ManyToManyField

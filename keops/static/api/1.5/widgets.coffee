widgetCount = 0


class Widget
  tag: 'div'
  constructor: ->
    @classes = ['form-field']

  ngModel: (attrs) ->
    'record.' + attrs.name

  getId: (id) ->
    return 'katrid-input-' + id.toString()

  widgetAttrs: (scope, el, attrs, field) ->
    r = {}
    if field.required
      r['required'] = null
    r['ng-model'] = @ngModel(attrs)
    r['ng-show'] = 'dataSource.changing'
    for attr, v of attrs when attr.startsWith 'field'
      attrName = attrs.$attr[attr]
      if attrName.startsWith('field-')
        attrName = attrName.substr(6, attrName.length - 6)
      r[attrName] = v
    if attrs.readonly?
      r['readonly'] = ''
    if @classes
      r['class'] = @classes.join(' ')
    return r

  _getWidgetAttrs: (scope, el, attrs, field) ->
    html = ''
    attributes = @widgetAttrs(scope, el, attrs, field)
    for att, v of attributes
      html += ' ' + att
      if v
        html += '="' + v + '"'
    if @placeholder
      html += " placeholder=\"#{@placeholder}\" "
    return html

  innerHtml: (scope, el, attrs, field) ->
    return ''

  labelTemplate: (scope, el, attrs, field) ->
    placeholder = ''
    label = field.caption
    if attrs.nolabel is 'placeholder'
      @placeholder = field.caption
      return ''
    else if attrs.nolabel
      return ''
    return """<label for="#{attrs._id}" class="form-label">#{label}</label>"""

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">${ record.#{attrs.name} || '--' }</span>"""

  widgetTemplate: (scope, el, attrs, field, type) ->
    if @tag.startsWith('input')
      html = """<#{@tag} id="#{attrs._id}" type="#{type}" name="#{attrs.name}" #{@_getWidgetAttrs(scope, el, attrs, field)}>"""
    else
      html = """<#{@tag} id="#{attrs._id}" name="#{attrs.name}" #{@_getWidgetAttrs(scope, el, attrs, field)}>"""
    inner = @innerHtml(scope, el, attrs, field)
    if inner
      html += inner + "</#{@tag}>"
    return html

  template: (scope, el, attrs, field, type='text') ->
    widgetCount++
    id = @getId(widgetCount)
    attrs._id = id
    html = '<div>' +
      @labelTemplate(scope, el, attrs, field) +
      @spanTemplate(scope, el, attrs, field) +
      @widgetTemplate(scope, el, attrs, field, type) +
      '</div>'
    return html

  link: (scope, el, attrs, $compile, field) ->
    # Add watcher for field dependencies
    if field.depends
      for dep in field.depends when dep not in scope.dataSource.fieldChangeWatchers
        scope.dataSource.fieldChangeWatchers.push(dep)
        scope.$watch 'record.' + dep, (newValue, oldValue) ->
          # Ignore if dataSource is not in changing state
          if newValue != oldValue and scope.dataSource.changing
            scope.model.onFieldChange(dep, scope.record)
            .done scope.dataSource.onFieldChange


class InputWidget extends Widget
  tag: 'input'
  constructor: ->
    super
    @classes.push('form-control')

  widgetTemplate: (scope, el, attrs, field, type='text') ->
    prependIcon = attrs.icon
    html = super(scope, el, attrs, field, type)
    if prependIcon
      return """<label class="prepend-icon" ng-show="dataSource.changing"><i class="icon #{prependIcon}"></i>#{html}</label>"""
    return html


class TextField extends InputWidget
  widgetAttrs: (scope, el, attrs, field) ->
    attributes = super(scope, el, attrs, field)
    if field.max_length
      attributes['maxlength'] = field.max_length.toString()
    return attributes


class SelectField extends InputWidget
  tag: 'select'

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">${ view.fields.#{attrs.name}.displayChoices[record.#{attrs.name}] || '--' }</span>"""

  innerHtml: (scope, el, attrs, field) ->
    return """<option ng-repeat="choice in view.fields.#{attrs.name}.choices" value="${choice[0]}">${choice[1]}</option>"""


class ForeignKey extends Widget
  tag: 'input foreignkey'

  spanTemplate: (scope, el, attrs, field) ->
    return """<a href="javascript:void(0)" class="form-field-readonly" ng-show="!dataSource.changing">${ record.#{attrs.name}[1] || '--' }</a>"""

  template: (scope, el, attrs, field) ->
    return super(scope, el, attrs, field, 'hidden')


class TextareaField extends TextField
  tag: 'textarea'


class DecimalField extends TextField
  tag: 'input decimal'

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">${ (record.#{attrs.name}|number:2) || '--' }</span>"""


class DateField extends TextField
  tag: 'input datepicker'

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">${ (record.#{attrs.name}|date:'#{Katrid.i18n.gettext('yyyy-mm-dd').replace(/[m]/g, 'M')}') || '--' }</span>"""

  widgetTemplate: (scope, el, attrs, field, type) ->
    html = super(scope, el, attrs, field, type)
    return """<div class="input-group date" ng-show="dataSource.changing">#{html}<div class="input-group-addon"><span class="glyphicon glyphicon-th"></span></div></div>"""


class OneToManyField extends Widget
  tag: 'grid'

  spanTemplate: (scope, el, attrs, field) ->
    return ''

  template: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'grid')
    return html


class ManyToManyField extends Widget
  tag: 'input foreignkey multiple'

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">${ record.#{attrs.name}|m2m }</span>"""

  template: (scope, el, attrs, field) ->
    return super(scope, el, attrs, field, 'hidden')


class CheckBox extends InputWidget
  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly bool-text" ng-show="!dataSource.changing">
${ record.#{attrs.name} ? Katrid.i18n.gettext('yes') : Katrid.i18n.gettext('no') }
</span>"""

  widgetTemplate: (scope, el, attrs, field) ->
    html = super(scope, el, attrs, field, 'checkbox')
    html = '<label class="checkbox" ng-show="dataSource.changing">' + html
    if field.help_text
      html += field.help_text
    else
      html += field.caption
    html += '<i></i></label>'
    return html

  labelTemplate: (scope, el, attrs, field) ->
    if field.help_text
      return super(scope, el, attrs, field)
    return """<label for="#{attrs._id}" class="form-label"><span ng-show="!dataSource.changing">#{field.caption}</span></label>"""


class FileField extends InputWidget
  tag: 'input file-reader'

  template: (scope, el, attrs, field, type='file') ->
    return super(scope, el, attrs, field, type)


class ImageField extends FileField
  template: (scope, el, attrs, field, type='file') ->
    return super(scope, el, attrs, field, type)

  widgetTemplate: (scope, el, attrs, field, type) ->
    html = super(scope, el, attrs, field, type)
    html = """<div class="image-box image-field">
<img src="/static/web/static/assets/img/avatar.png"/>
  <div class="text-right image-box-buttons">
  <button class="btn btn-default" type="button" title="#{Katrid.i18n.gettext 'Change'}"><i class="fa fa-pencil"></i></button>
  <button class="btn btn-default" type="button" title="#{Katrid.i18n.gettext 'Clear'}"><i class="fa fa-trash"></i></button>
  </div>
    #{html}</div>"""
    return html

class PasswordField extends InputWidget
  template: (scope, el, attrs, field, type='password') ->
    return super(scope, el, attrs, field, type)

  spanTemplate: (scope, el, attrs, field) ->
    return """<span class="form-field-readonly" ng-show="!dataSource.changing">*******************</span>"""


@Katrid.UI.Widgets =
  Widget: Widget
  InputWidget: InputWidget
  TextField: TextField
  SelectField: SelectField
  ForeignKey: ForeignKey
  TextareaField: TextareaField
  DecimalField: DecimalField
  DateField: DateField
  CheckBox: CheckBox
  OneToManyField: OneToManyField
  ManyToManyField: ManyToManyField
  FileField: FileField
  PasswordField: PasswordField

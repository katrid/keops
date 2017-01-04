

class Templates
  getViewRenderer: (viewType) ->
    return @["render_" + viewType]

  getViewModesButtons: (scope) ->
    act = scope.action
    buttons =
      list: '<button class="btn btn-default" type="button" ng-click="action.setViewType(\'list\')"><i class="fa fa-list"></i></button>'
      form: '<button class="btn btn-default" type="button" ng-click="action.setViewType(\'form\')"><i class="fa fa-edit"></i></button>'
      calendar: '<button class="btn btn-default" type="button" ng-click="action.setViewType(\'calendar\')"><i class="fa fa-calendar"></i></button>'
      chart: '<button class="btn btn-default" type="button" ng-click="action.setViewType(\'chart\')"><i class="fa fa-bar-chart-o"></i></button>'
    return buttons

  # buttons group include
  getViewButtons: (scope) ->
    act = scope.action
    buttons = @getViewModesButtons(scope)
    r = []
    for vt in act.viewModes
      r.push(buttons[vt])
    return '<div class="btn-group">' + r.join('') + '</div>'

  gridDialog: ->
    """
  <div ng-form="form" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <h4 class="modal-title" id="myModalLabel">${field.caption}</h4>
        </div>
        <div ng-form="form" class="modal-body">
  <div class="row">
  <!-- view content -->
  </div>
  <div class="clearfix"></div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" type="button" ng-click="save()">#{Katrid.i18n.gettext 'Save'}</button>
          <button type="button" class="btn btn-default" type="button" data-dismiss="modal">#{Katrid.i18n.gettext 'Cancel'}</button>
        </div>
      </div>
    </div>
  </div>
  """

  render_form: (scope, html) ->
    buttons = @getViewButtons(scope)
    actions = ''
    if scope.view.view_actions
      for act in scope.view.view_actions
        actions += """<li><a href="javascript:void(0)" ng-click="action.doViewAction('#{act.name}', record.id)">#{act.title}</a></li>"""
    return """
<div ng-form="form"><div class=\"data-heading panel panel-default\">
    <div class=\"panel-body\">
      <div>
        <a href=\"javascript:void(0)\" title=\"Add to favorite\"><i class=\"fa star fa-star-o pull-right\"></i></a>
        <ol class=\"breadcrumb\">
          <li><a href=\"javascript:void(0)\" ng-click=\"action.setViewType(\'list\')\">${ action.info.display_name }</a></li>
          <li>${ (dataSource.loadingRecord && Katrid.i18n.gettext('Loading...')) || record.display_name }</li>
        </ol>
        <div class=\"pull-right\">
            <span ng-show="records.length">
              ${dataSource.recordIndex} / ${records.length}
            </span>
        </div>
        <p class=\"help-block\">${ action.info.usage }&nbsp;</p>
      </div>
      <div class=\"toolbar\">
  <button class=\"btn btn-primary\" type=\"button\" ng-disabled="dataSource.uploading" ng-click=\"dataSource.saveChanges()\">#{Katrid.i18n.gettext 'Save'}</button>
  <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.cancelChanges()\"><i class=\"fa fa-fw fa-remove text-danger\"></i> #{Katrid.i18n.gettext 'Cancel'}</button>
  <div class=\"btn-group\">
    <button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\">
      #{Katrid.i18n.gettext 'Action'} <span class=\"caret\"></span></button>
    <ul class=\"dropdown-menu animated flipInX\">
      <li><a href='javascript:void(0)' ng-click=\"action.deleteSelection()\"><i class=\"fa fa-fw fa-trash\"></i> #{Katrid.i18n.gettext 'Delete'}</a></li>
      #{actions}
    </ul>
  </div>
  <div class=\"pull-right\">
    <div class=\"btn-group\" role=\"group\">
      <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.prior(\'form\')\"><i class=\"fa fa-chevron-left\"></i>
      </button>
      <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.next(\'form\')\"><i class=\"fa fa-chevron-right\"></i>
      </button>
    </div>\n
    #{buttons}
</div>
</div>
    </div>
  </div><div class=\"content container animated fadeIn\"><div class=\"panel panel-default data-panel\">
<div class=\"panel-body\"><div class=\"row\">#{html}</div></div></div></div></div>"""
    return html

  render_list: (scope, html) ->
    buttons = @getViewButtons(scope)
    """<div class=\"data-heading panel panel-default\">
    <div class=\"panel-body\">
      <div>
        <a href=\"javascript:void(0)\" title=\"Add to favorite\"><i class=\"fa star fa-star-o pull-right\"></i></a>
        <ol class=\"breadcrumb\">
          <li>${ action.info.display_name }</li>
        </ol>
        <div class=\"pull-right\">
            <span>
              <strong>${dataSource.offset|number} - ${dataSource.offsetLimit|number}</strong> of <strong>${dataSource.recordCount|number}</strong>
            </span>
        </div>
        <p class=\"help-block\">${ action.info.usage }&nbsp;</p>
      </div>
      <div class=\"toolbar\">
  <button class=\"btn btn-primary\" type=\"button\" ng-click=\"action.createNew()\">#{Katrid.i18n.gettext 'Create'}</button>
  <span ng-show="dataSource.loading" class="badge page-badge-ref fadeIn animated">${dataSource.pageIndex}</span>

  <div class=\"btn-group\">
    <button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\">
      #{Katrid.i18n.gettext 'Action'} <span class=\"caret\"></span></button>
    <ul class=\"dropdown-menu animated flipInX\">
      <li><a href='javascript:void(0)' ng-click=\"action.deleteSelection()\"><i class=\"fa fa-fw fa-trash\"></i> #{Katrid.i18n.gettext 'Delete'}</a></li>
    </ul>
  </div>

  <div class=\"pull-right\">
    <div class=\"btn-group\">
      <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.prevPage()\"><i class=\"fa fa-chevron-left\"></i>
      </button>
      <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.nextPage()\"><i class=\"fa fa-chevron-right\"></i>
      </button>
    </div>\n
    #{buttons}
</div>
</div>
    </div>
  </div><div class=\"content no-padding\">
<div class=\"panel panel-default data-panel\">
<div class=\"panel-body no-padding\">
<div class=\"dataTables_wrapper form-inline dt-bootstrap no-footer\">#{html}</div></div></div></div>"""

  renderList: (scope, element, attrs, rowClick) ->
    ths = ''
    cols = ''
    for col in element.children()
      name = $(col).attr('name')
      fieldInfo = scope.view.fields[name]

      if fieldInfo.choices
        fieldInfo._listChoices = {}
        for choice in fieldInfo.choices
          fieldInfo._listChoices[choice[0]] = choice[1]

      cls = """#{fieldInfo.type} field-#{name}"""
      ths += """<th class="#{cls}"><label>${view.fields.#{name}.caption}</label></th>"""
      cls = """#{fieldInfo.type} field-#{name}"""
      if fieldInfo.type is 'ForeignKey'
        cols += """<td><a href="javscript:void(0)" ng-click="$event.stopPropagation();" data-id="${row.#{name}[0]}">${row.#{name}[1]}</a></td>"""
      else if  fieldInfo._listChoices
        cols += """<td class="#{cls}">${view.fields.#{name}._listChoices[row.#{name}]}</td>"""
      else if fieldInfo.type is 'BooleanField'
        cols += """<td>${row.#{name} ? '#{Katrid.i18n.gettext('yes')}' : '#{Katrid.i18n.gettext('no')}'}</td>"""
      else if fieldInfo.type is 'DecimalField'
        cols += """<td class="#{cls}">${row.#{name}|number:2}</td>"""
      else if fieldInfo.type is 'DateField'
        cols += """<td class="#{cls}">${row.#{name}|date:shortDate}</td>"""
      else
        cols += """<td>${row.#{name}}</td>"""
    if not rowClick?
      rowClick = 'dataSource.setRecordIndex($index);action.location.search({view_type: \'form\', id: row.id});'
    s = """<table ng-show="!dataSource.loading" class="table table-striped table-bordered table-hover display responsive nowrap dataTable no-footer dtr-column">
<thead><tr>#{ths}</tr></thead>
<tbody>
<tr ng-repeat="row in records" ng-click="#{rowClick}">#{cols}</tr>
</tbody>
</table>
<div ng-show="dataSource.loading" class="col-sm-12 margin-bottom-16 margin-top-16">#{Katrid.i18n.gettext 'Loading...'}</div>
"""
    return s

  renderGrid: (scope, element, attrs, rowClick) ->
    tbl = @renderList(scope, element, attrs, rowClick)
    return """<div><div><button class="btn btn-default" ng-click="addItem()" type="button">#{Katrid.i18n.gettext 'Add'}</button></div>#{tbl}</div>"""

@Katrid.UI.Utils =
  Templates: new Templates()

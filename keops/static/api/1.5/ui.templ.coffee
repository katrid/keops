
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
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <h4 class="modal-title" id="myModalLabel">${field.caption}</h4>
        </div>
        <div class="modal-body">
  <div class="row">
  <!-- view content -->
  </div>
  <div class="clearfix"></div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" type="button" ng-click="save()" ng-show="dataSource.changing">#{Katrid.i18n.gettext 'Save'}</button>
          <button type="button" class="btn btn-default" type="button" data-dismiss="modal" ng-show="dataSource.changing">#{Katrid.i18n.gettext 'Cancel'}</button>
          <button type="button" class="btn btn-default" type="button" data-dismiss="modal" ng-show="!dataSource.changing">#{Katrid.i18n.gettext 'Close'}</button>
        </div>
      </div>
    </div>
  </div>
  """

  preRender_form: (scope, html) ->
    buttons = @getViewButtons(scope)
    actions = ''
    if scope.view.view_actions
      for act in scope.view.view_actions
        if act.confirm
          confirmation = ", '" + act.confirm + "'"
        else
          confirmation = ''
        actions += """<li><a href="javascript:void(0)" ng-click="action.doViewAction('#{act.name}', record.id#{confirmation})">#{act.title}</a></li>"""
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
  <button class=\"btn btn-primary\" type=\"button\" ng-disabled="dataSource.uploading" ng-click=\"dataSource.saveChanges()\" ng-show="dataSource.changing">#{Katrid.i18n.gettext 'Save'}</button>
  <button class=\"btn btn-primary\" type=\"button\" ng-disabled="dataSource.uploading" ng-click=\"dataSource.editRecord()\" ng-show="!dataSource.changing">#{Katrid.i18n.gettext 'Edit'}</button>
  <button class=\"btn btn-default\" type=\"button\" ng-disabled="dataSource.uploading" ng-click=\"dataSource.newRecord()\" ng-show="!dataSource.changing">#{Katrid.i18n.gettext 'Create'}</button>
  <button class=\"btn btn-default\" type=\"button\" ng-click=\"dataSource.cancelChanges()\" ng-show="dataSource.changing">#{Katrid.i18n.gettext 'Cancel'}</button>
  <div class=\"btn-group\">
    <button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\">
      #{Katrid.i18n.gettext 'Action'} <span class=\"caret\"></span></button>
    <ul class=\"dropdown-menu animated flipInX\">
      <li><a href='javascript:void(0)' ng-click=\"action.deleteSelection()\"><i class=\"fa fa-fw fa-trash\"></i> #{Katrid.i18n.gettext 'Delete'}</a></li>
      <li><a href='javascript:void(0)' ng-click=\"action.copy()\"><i class=\"fa fa-fw fa-files-o\"></i> #{Katrid.i18n.gettext 'Duplicate'}</a></li>
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

  preRender_list: (scope, html) ->
    buttons = @getViewButtons(scope)
    """<div class=\"data-heading panel panel-default\">
    <div class=\"panel-body\">
      <div class='row'>
        <div class="col-sm-6">
        <ol class="breadcrumb">
          <li>${ action.info.display_name }</li>
        </ol>
        </div>
        <search-view class="col-md-6"/>
        <!--<p class=\"help-block\">${ action.info.usage }&nbsp;</p>-->
      </div>
      <div class="row">
      <div class="toolbar">
<div class="col-sm-6">
        <button class=\"btn btn-primary\" type=\"button\" ng-click=\"action.createNew()\">#{Katrid.i18n.gettext 'Create'}</button>
        <span ng-show="dataSource.loading" class="badge page-badge-ref fadeIn animated">${dataSource.pageIndex}</span>

  <div class=\"btn-group\">
    <button type=\"button\" class=\"btn btn-default dropdown-toggle\" data-toggle=\"dropdown\" aria-haspopup=\"true\">
      #{Katrid.i18n.gettext 'Action'} <span class=\"caret\"></span></button>
    <ul class=\"dropdown-menu animated flipInX\">
      <li><a href='javascript:void(0)' ng-click=\"action.deleteSelection()\"><i class="fa fa-fw fa-trash"></i> #{Katrid.i18n.gettext 'Delete'}</a></li>
    </ul>
  </div>

  <button class="btn btn-default" ng-click="dataSource.refresh()"><i class="fa fa-refresh"></i> Atualizar</button>

</div>
<div class="col-sm-6">
  <div class="btn-group animated fadeIn search-view-more-area" ng-show="search.viewMoreButtons">
    <button class="btn btn-default"><span class="fa fa-filter"></span> #{Katrid.i18n.gettext('Filters')} <span class="caret"></span></button>
    <button class="btn btn-default"><span class="fa fa-bars"></span> #{Katrid.i18n.gettext('Group By')} <span class="caret"></span></button>
    <ul class="dropdown-menu animated flipInX search-view-groups-menu">
    </ul>
    <button class="btn btn-default"><span class="fa fa-star"></span> #{Katrid.i18n.gettext('Favorites')} <span class="caret"></span></button>
  </div>

  <div class=\"pull-right\">
            <div class="pagination-area">
              <span class="paginator">${dataSource.offset|number} - ${dataSource.offsetLimit|number}</span> / <span class="total-pages">${dataSource.recordCount|number}</span>
            </div>
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
</div>
    </div>
  </div><div class=\"content no-padding\">
<div class=\"panel panel-default data-panel\">
<div class=\"panel-body no-padding\">
<div class=\"dataTables_wrapper form-inline dt-bootstrap no-footer\">#{html}</div></div></div></div>"""

  renderList: (scope, element, attrs, rowClick, parentDataSource) ->
    ths = '<th ng-show="dataSource.groups.length"></th>'
    cols = """<td ng-show="dataSource.groups.length" class="group-header">
<div ng-show="row._group">
<span class="fa fa-fw fa-caret-right"
  ng-class="{'fa-caret-down': row._group.expanded, 'fa-caret-right': row._group.collapsed}"></span>
  ${row._group.__str__} (${row._group.count})</div></td>"""

    for col in element.children()
      col = $(col)
      name = col.attr('name')
      if not name
        cols += """<td>#{col.html()}</td>"""
        ths += """<th><label>${col.attr('caption')}</label></th>"""
        continue

      if col.attr('visible') is 'False'
        continue


      name = col.attr('name')
      fieldInfo = scope.view.fields[name]

      if fieldInfo.choices
        fieldInfo._listChoices = {}
        for choice in fieldInfo.choices
          fieldInfo._listChoices[choice[0]] = choice[1]

      cls = """#{fieldInfo.type} list-column"""
      ths += """<th class="#{cls}" name="#{name}"><label>${view.fields.#{name}.caption}</label></th>"""
      cls = """#{fieldInfo.type} field-#{name}"""

      colHtml = col.html()

      if colHtml
        cols += """<td><a data-id="${row.#{name}[0]}">#{colHtml}</a></td>"""
      else if fieldInfo.type is 'ForeignKey'
        cols += """<td><a data-id="${row.#{name}[0]}">${row.#{name}[1]}</a></td>"""
      else if  fieldInfo._listChoices
        cols += """<td class="#{cls}">${view.fields.#{name}._listChoices[row.#{name}]}</td>"""
      else if fieldInfo.type is 'BooleanField'
        cols += """<td>${row.#{name} ? '#{Katrid.i18n.gettext('yes')}' : '#{Katrid.i18n.gettext('no')}'}</td>"""
      else if fieldInfo.type is 'DecimalField'
        cols += """<td class="#{cls}">${row.#{name}|number:2}</td>"""
      else if fieldInfo.type is 'DateField'
        cols += """<td class="#{cls}">${row.#{name}|date:'shortDate'}</td>"""
      else
        cols += """<td>${row.#{name}}</td>"""
    if parentDataSource
      ths += """<th class="list-column-delete" ng-show="parent.dataSource.changing">"""
      cols += """<td class="list-column-delete" ng-show="parent.dataSource.changing" ng-click="removeItem($index);$event.stopPropagation();"><i class="fa fa-trash"></i></td>"""
    if not rowClick?
      rowClick = 'action.listRowClick($index, row)'
    s = """<table ng-show="!dataSource.loading" class="table table-striped table-bordered table-hover display responsive nowrap dataTable no-footer dtr-column">
<thead><tr>#{ths}</tr></thead>
<tbody>
<tr ng-repeat="row in records" ng-click="#{rowClick}" ng-class="{'group-header': row._hasGroup}">#{cols}</tr>
</tbody>
</table>
<div ng-show="dataSource.loading" class="col-sm-12 margin-bottom-16 margin-top-16">#{Katrid.i18n.gettext 'Loading...'}</div>
"""
    return s

  renderGrid: (scope, element, attrs, rowClick) ->
    tbl = @renderList(scope, element, attrs, rowClick, true)
    return """<div><div><button class="btn btn-default" ng-click="addItem()" ng-show="parent.dataSource.changing" type="button">#{Katrid.i18n.gettext 'Add'}</button></div>#{tbl}</div>"""

@Katrid.UI.Utils =
  Templates: new Templates()

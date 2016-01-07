var ui = angular.module('ui.erp', []);

var _keopsWidgetCount = 0;

var getFormat = function (fmtName) {
  return katrid.get_format(fmtName);
};

ui.directive('field', function ($compile) {
  return {
    restrict: 'E',
    replace: true,
    template: function (element, attrs) {
      var html = pre = pos = cols = icon = cls = fieldAttrs = contentField = nm = '';
      var lbl = nolabel = null;
      var tp = 'text';
      _keopsWidgetCount++;
      var widgetId = 'k-input-' + _keopsWidgetCount.toString();

      for (var attr in attrs) {
        if (attr === 'label') lbl = attrs.label;
        else if (attr === 'cols') cols = attrs.cols;
        else if (attr === 'type') tp = attrs.type;
        else if (attr === 'nolabel') {
          nolabel = attrs.nolabel;
          delete attrs.nolabel;
        }
        else if (attr === 'icon') icon = '<i class="' + attrs.icon + '"></i>';
        else if (attr === 'mask') fieldAttrs += ' ui-mask="' + attrs.mask + '" ui-mask-placeholder-char="space"';
        else if (attr === 'class') cls = attrs.class;
        else if (attr === 'ngShow') continue;
        else if (attr === 'ngmodel') {
          nm = attrs.ngmodel;
          fieldAttrs += ' ng-model="' + nm + '"';
          delete attrs.ngmodel;
        }
        else if (attr === 'ngServerChange') {
          fieldAttrs += ' server-change="' + attrs[attr] + '"';
          delete attrs.ngServerChange;
        }
        else if (attr === 'ngClientChange') {
          fieldAttrs += ' ng-change="' + attrs[attr] + '"';
          delete attrs.ngServerChange;
        }
        else if (attr === 'ngSubfieldChange') {
          fieldAttrs += ' subfield-change="' + attrs[attr] + '"';
          delete attrs.ngSubfieldChange;
        }
        else if (attr === 'ngCalcExpression') {
          fieldAttrs += ' calc-expression="' + attrs[attr] + '"';
          delete attrs.ngCalcExpression;
        }
        else if (attr.substring(0, 2) === 'ng') {
          fieldAttrs += ' ng-' + attr.substring(2) + '="' + attrs[attr] + '"';
          delete attrs[attr];
        }
        else if (attr === 'contentField') {
          contentField = attrs.contentField;
          delete attrs.contentField;
        }
        else if ((attr === 'maxlength') && (attrs.mask)) {
          attrs.maxlength = '';
          fieldAttrs += ' ' + attr + '="' + attrs[attr] + '"';
        }
        else if (attr === 'helpText') {
          if (attrs.type === 'checkbox') {
            pos += attrs.helpText;
          } else {
            pre += '<i class="icon-append fa fa-question-circle"></i>';
            pos += '<b class="tooltip tooltip-top-right"><i class="fa fa-warning txt-color-teal"></i> ' + attrs.helpText + ' </b>';
          }
        }
        else if (attr[0] !== '$') {
          fieldAttrs += ' ' + attr + '="' + attrs[attr] + '"';
          if (attr !== 'name') delete attrs[attr];
        }
      }
      attrs.class = '';
      attrs.ngBind = null;
      //attrs.label = null;
      delete attrs.cols;
      var nm = nm || attrs.ngModel;
      if (!nm) {
        nm = 'form.data.' + attrs.name;
        fieldAttrs += ' ng-model="' + nm + '"';
      }
      if (nm) {
        var _nm = nm.split('.');
        var elname = _nm[_nm.length - 1];
        if (!attrs.name) fieldAttrs += ' name="' + elname + '"';
        if (!attrs.id) fieldAttrs += ' id="' + widgetId + '"';
      }
      var el = $(element[0]);
      var elHtml = el.html();
      //if ((tp === "decimal") || (tp === "int")) cls = 'text-right';
      if (tp === "decimal") {
        html = pre + '<input type="text" decimal="decimal" class="form-control numeric-field ' + cls + '" ' + fieldAttrs + '>' + pos + elHtml;
      } else if (tp === "int") {
        html = pre + '<input type="text" decimal="decimal" precision="0" class="form-control numeric-field ' + cls + '" ' + fieldAttrs + '>' + pos + elHtml;
      } else if (tp === "text") {
        if (icon) {
          pre += '<div class="input-group"><span class="input-group-addon">' + icon + '</span>';
          pos = '</div>' + pos;
        }
        html = pre + '<input type="text" class="form-control ' + cls + '" ' + fieldAttrs + '/>' + pos + elHtml;
      } else if (tp === "select") {
        html = '<select class="form-control" ' + fieldAttrs + '>' + elHtml + '</select>';
      } else if (tp === "checkbox") {
        if (attrs.label && !attrs.helpText) {
          pos += attrs.label;
          lbl = '';
        }
        html = '<div class="checkbox"><label><input type="checkbox" ' + fieldAttrs + '>' + elHtml + pos + '</label></div>';
      } else if (tp === "textarea") {
        html = pre + '<textarea class="form-control" ' + fieldAttrs + '>' + elHtml + '</textarea>' + pos;
      } else if (tp === 'lookup') {
        if (attrs.multiple) fieldAttrs += ' multiple';
        html = '<input type="text" ' + fieldAttrs + ' ui-select="' + contentField + '" style="width: 100%;" />';
      } else if (tp === 'date') {
        html = '<input class="form-control" type="text" ' + fieldAttrs + ' ui-datepicker />';
      } else if (tp === 'datetime') {
        html = '<input class="form-control" type="text" ' + fieldAttrs + ' ui-datetimepicker />';
      } else if (tp === 'grid') {
        html = '<grid ' + fieldAttrs + ' label="' + attrs.label + '" content-field="' + contentField + '">' + elHtml + '</grid>';
      } else if (tp === 'static') {
        html = '<p class="form-control-static ' + cls + '" ' + fieldAttrs + '>' + elHtml + '</p>';
      }
      if ((lbl !== null) && !nolabel) {
        lbl = '<label class="control-label" for="' + widgetId + '">' + lbl + '</label>';
      } else lbl = '';
      if (cols) {
        cols = 'class="col-sm-' + cols + '"';
      } else cols = "class='col-sm-12'";
      html = '<section ' + cols + '>' + lbl + html + '</section>';
      delete attrs.name;
      return html;
    }
  }
});

ui.directive('calcExpression', function () {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function(scope, el, attrs, ctrl) {
      scope.$watch(attrs.calcExpression, function(newValue, oldValue) {
        if (scope.form.data) scope.form.data[attrs.name] = newValue;
      });
    }
  }
});

ui.directive('ngSum', function () {
  return {
    restrict: 'A',
    priority: 11,
    require: '?ngModel',
    link: function (scope, el, attrs, ctrl) {
      if (attrs.ngSum) {
        var f = attrs.ngSum.split('.');
        var s = f.pop();
        f = f.join('.');
        var fn = function() {
          if (scope.form.data) {
            var v = 0;
            var lst = scope.$eval(f);
            for (var i=0;i<scope.form.data[f.split('.').pop()].length;i++) v += parseFloat(lst[i][s]);
            scope.form.data[attrs.name] = v;
            if (ctrl) ctrl.$setDirty();
          }
        };
        if (!scope._counters[f]) scope._counters[f] = [];
        scope._counters[f].push(fn);
      }
    }
  }
});

ui.directive('subfieldChange', function () {
  return {
    restrict: 'A',
    require: 'ngModel',
    priority: 10,
    link: function(scope, element, attrs, ctrl) {
      var parent = $(element).closest('[content-field]').attr('content-field');
      ctrl.$viewChangeListeners.push(function() {
        if (parent) scope.fieldChangeNotification(parent, attrs.subfieldChange);
      });
    }
}});

ui.directive('serverChange', function () {
  return {
    restrict: 'A',
    require: 'ngModel',
    priority: 11,
    link: function(scope, element, attrs, ctrl) {
      var nm = attrs.serverChange;
      ctrl.$viewChangeListeners.push(function() {
        if (nm.indexOf('.')) scope.$parent.fieldChangeNotification(attrs.serverChange);
        else scope.fieldChangeNotification(attrs.serverChange);
      });
    }
}});

ui.directive('actions', function ($compile) {
  return {
    restrict: 'E',
    replace: true,
    template: function (tElement, attrs) {
      var html = tElement.html();
      var groups = tElement.children();
      var r = '<div class="actions">';
      groups.each(function () {
        var group = this;
        var _attrs = '';
        $(group.attributes).each(function () {
          if (this.nodeName != 'class') _attrs += ' ' + this.nodeName + '="' + this.nodeValue + '"';
        });
        var cls = $(group).attr('class');
        if (!cls) cls = 'btn-default';
        if (group.nodeName === 'ACTION') {
          r += '<button class="btn btn-margin ' + cls + '"' + _attrs + '>' + group.innerHTML + '</button>';
        }
        else if (group.nodeName === 'ACTION-GROUP') {
          r += '<div class="btn-group btn-margin"><a class="btn dropdown-toggle ' + cls + '"' + _attrs + ' data-toggle="dropdown" href="javascript:void(0);">' + $(group).attr('heading') + ' <span class="caret"></span></a><ul class="dropdown-menu" role="menu">';
          var actions = $(group).children();
          actions.each(function () {
            var action = this;
            r += '<li><a href="javascript:void(0);">' + action.innerHTML + '</a></li>'
            //'<div class="btn-group btn-margin"><a class="btn btn-default dropdown-toggle" data-toggle="dropdown" href="javascript:void(0);">Ações <span class="caret"></span></a><ul class="dropdown-menu"><li><a href="javascript:void(0);">Exportar Dados</a></li></ul></div>'
          });
          r += '</ul></div>'
        }
      });
      return r + '</div>';
    }
  }
});


ui.directive('contentObject', function ($compile) {
  return {
    restrict: 'A',
    replace: true,
    template: function (tElement, tAttrs) {
      var attrs = tAttrs;

      var children = tElement.children();
      var sparks = '';
      for (var i = 0; i < children.length; i++) {
        var child = children[i];
        if (child.nodeName === 'SPARKS') sparks = '<ul id="sparks">' + child.innerHTML + '</ul>';
      }
      tElement.find('sparks').remove();

      var html = tElement.html();
      var node = tElement[0].nodeName;
      if (node === 'LIST') {
        var cols = tElement.children();
        var th = '<th class="checkbox-action"><input id="action-toggle" type="checkbox" ng-click="toggleCheckAll();" /></th>';
        var td = '<td><input type="checkbox" class="action-select" ng-click="selectItem(item)" /></td>';
        for (i = 0; i < cols.length; i++) {
          var col = $(cols[i]);
          if (col[0].nodeName === 'ACTIONS') {
            var actions = col[0];
            continue;
          }
          var css = col.attr('class');
          var tp = col.attr('type');
          if (!css) css = tp ? ' class="' + tp + '"' : '';
          else css = ' class="' + css + '"';
          var lbl = col.attr('label');
          if (!lbl) lbl = '';
          th += '<th' + css + '>' + col.attr('label') + '</th>';
          var modelField = 'item.' + col.attr('name');
          var fmt = col.attr('format');

          switch (tp) {
            case 'date':
              modelField = '(' + modelField + '|';
              if (fmt) modelField += fmt;
              else modelField += "date:'shortDate'";
              modelField += ')';
              break;
            case 'datetime':
              modelField = '(' + modelField + '|';
              if (fmt) modelField += fmt;
              else modelField += "date:'short'";
              modelField += ')';
              break;
            case 'decimal':
              modelField = '(' + modelField + '|';
              if (fmt) modelField += fmt;
              else modelField += 'number:2';
              modelField += ')';
              break;
          }

          td += '<td ' + css + ' ng-click="list.itemClick(item)" ng-bind="' + modelField + '"></td>';
        }

        var model = attrs.contentObject;

        var paginator = '<div class="pull-right nav-paginator">' +
            '<label class="nav-recno-info">1-{{ list.items.length }} de {{ list.total }}</label>' +
            '<a class="btn btn-default"><i class="fa fa-chevron-left"></i></a>' +
            '<a class="btn btn-default"><i class="fa fa-chevron-right"></i></a>' +
            '</div>';

        var nhtml = '<div ng-controller="ListController">' +
            '<div class="row view-header">' +
            '<div>' +
            '<div>' +
            '<h1 class="page-title txt-color-blueDark col-sm-6"><i class="fa fa-table fa-fw "></i>' + attrs.viewTitle + '</h1>' +
            '<form class="header-search pull-right">' +
            '<input id="search-fld" type="text" placeholder="' + katrid.gettext('Quick Search') + '" ng-model="queryField" ng-enter="list.query(queryField)">' +
            '<button type="button" ng-click="list.query(queryField)"><i class="fa fa-search"></i></button><a href="javascript:void(0);" id="cancel-search-js" title="Cancel Search"><i class="fa fa-times"></i></a></form>' +
            '</div>' +
            '<div class="col-sm-12 view-toolbar">' +
            '<button class="btn btn-danger view-toolbutton" ng-click="newItem()"> ' + katrid.gettext('Create') + ' </button>' +
            '<button class="btn btn-default view-toolbutton" ng-show="list.selection" ng-click="list.deleteSelection();">' +
            '<span class="glyphicon glyphicon-trash"></span> ' + katrid.gettext('Delete') + '</button>' +
              //actions.outerHTML +
            '<div class="btn-group view-toolbutton">' +
            '<a class="btn btn-default dropdown-toggle" data-toggle="dropdown" href="javascript:void(0);">' + katrid.gettext('Actions') + ' <span class="caret"></span></a>' +
            '<ul class="dropdown-menu"><li><a href="javascript:void(0);">Exportar Dados</a></li></ul>' +
            '</div>' +
            '<div class="btn-group pull-right view-mode-buttons"><button type="button" class="btn btn-default active" title="Ir para pesquisa"><i class="fa fa-table"></i></button><button type="button" class="btn btn-default" title="Exibir formulário" ng-click="showForm(list.items[0].pk)"><i class="fa fa-edit"></i></button></div>' +
            '</div>' +
            '</div></div>' +
            '<div class="row"><article class="col-sm-12">' +
            '<div>' +
            '<div role="content">' +
            '<div class="list-content">' +
            '<div><div class="col-sm-6"><p class="row" ng-show="list.selection === 1">' + katrid.gettext('1 Item selected.') + '</p>' +
            '<p class="row" ng-show="list.selection > 1">' + katrid.gettext('{{ list.selection }} Items selected.') + '</p>' +
            '<p class="row" ng-show="!list.selection">' + katrid.gettext('No selected data.') + '</p></div>' +
            '<div class="pull-right" style="margin-top: -4px;">' +
            paginator +
            '</div>' +
            '</div>' +
            '<table class="table table-hover table-bordered table-striped table-condensed" ng-init="list.init(\'' + model + '\', list.q);"><thead><tr>' + th + '</tr></thead>' +
            '<tbody>' +
            '<tr ng-repeat="item in list.items" class="table-row-clickable">' +
            td +
            '</tr></tbody></table>' +
            '<div class="dt-toolbar-footer"><div class="col-sm-6 col-xs-12 hidden-xs">' +
            '<div>Total de Registros: {{ list.total | number }}<br />' +
            'Exibindo de <span class="txt-color-darken">{{ list.start - list.items.length + 1 }}</span> até <span class="txt-color-darken">{{ list.start }}</span></div></div>' +
            '<div class="col-sm-6 col-xs-12">' +
            '<div class="data-table-paginate paging_simple_numbers" style="margin-top: 0">' +
            paginator +
            '</div></div></div>' +
            '</div></div></div>' +
            '</article></div></div>';
        return nhtml;

      }
      else {
        var model = attrs.contentObject;
        var nhtml = '<div ng-controller="FormController" ng-init="form.init(\'' + model + '\')">' +
            '<div class="row view-header">' +
            '<div>' +
            '<div class="col-xs-12 col-sm-7 col-md-7 col-lg-4">' +
            '<h1 class="page-title txt-color-blueDark">' +
            '<i class="fa-fw fa fa-pencil-square-o"></i>' + attrs.viewTitle + ' <span>/ {{ form.data.__str__ }}</span><span ng-show="!form.data.pk">&nbsp;</span></h1>' +
            '</div><div class="col-xs-12 col-sm-5 col-md-5 col-lg-8">' +
            sparks +
            '</div></div>' +
            '<div class="col-sm-12 view-toolbar">' +
            '<button type="button" class="btn btn-danger view-toolbutton" title="Salvar" ng-click="submit()">Salvar</button>' +
            '<button ng-click="showList()" class="btn btn-default view-toolbutton">Cancelar</button>' +
            '<div class="btn-group pull-right view-mode-buttons"><button type="button" class="btn btn-default" title="Ir para pesquisa" ng-click="showList()"><i class="fa fa-table"></i></button><button type="button" class="btn btn-default active" title="Exibir formulário"><i class="fa fa-edit"></i></button></div>' +

            '<div class="pull-right nav-paginator" style="margin-right: 10px;">' +
            '<label class="nav-recno-info">1 / 1</label>' +
            '<a class="btn btn-default"><i class="fa fa-chevron-left"></i></a>' +
            '<a class="btn btn-default"><i class="fa fa-chevron-right"></i></a>' +
            '</div>' +

            '</div></div>' +
            '<div class="row form-content">' +
            '<div> ' +
            '<div>' +
            '<div class="widget-body">' +
            '<form name="dataForm" ng-submit="submit()" novalidate>' +
            html +
            '</form></div></div></div></div></div>';
        return nhtml;
      }
    }
  }
});

var _subInsert = function (dataSet, obj) {
  if (!(obj in dataSet.inserted)) dataSet.inserted.push(obj);
};

var _subDelete = function (dataSet, obj) {
  if (!(obj in dataSet.deleted)) dataSet.deleted.push(obj);
};

var _subUpdate = function (dataSet, obj) {
  if (!(obj in dataSet.updated)) dataSet.inserted.push(obj);
};


ui.directive('formset', function ($compile, $http) {
  var fields = [];
  return {
    restrict: 'E',
    replace: true,
    scope: {},
    link: function (scope, el, attrs, controller) {
      var parentForm = scope.$parent.form;
      var contentField = attrs.contentField;
      var fname = contentField.split('.');
      var url = '/api/content/' + fname[0] + '/' + fname[1] + '/';
      var nm = attrs.name;

      scope.form = parentForm;
      scope.form.addChild(nm);

      scope.$parent.$watch(parentForm.pk, function (value) {
        masterChange(value);
      });

      var masterChange = function (masterKey) {
        if (parentForm.pk) {
          var params = {
            field: fname[2],
            fields: fields,
            mode: 'grid',
            id: parentForm.pk
          };
          $http({
            url: url,
            params: params
          }).success(function (data) {
            scope.items = data.items;
            parentForm.data[nm] = data.items;
          }.bind(true));
        } else {
          scope.items = [];
        }
      }
    },
    template: function (el, attrs) {
      el.find('field').each(function () {
        var field = $(this).attr('name');
        fields.push(field);
      });
      var html = el.html();
      var nm = attrs.name;
      var r = '<div name=""' + nm + '">' +
          '<div class="row" ng-form="' + nm + '-{{$index}}" ng-repeat="item in form.data.' + nm + '">' +
          html +
          '</div>' +
            //'<div class="col-sm-12 margin-top-10"><button type="button" class="btn btn-default btn-sm" ng-click="form.data.' + nm + '.push({})">Adicionar</button></div>' +
          '</div>';
      return r;
    }
  }
});


ui.directive('subForm', function ($http) {
  var fields = [];
  return {
    restrict: 'E',
    replace: true,
    link: function (scope, el) {
      scope.formFields = fields;
      scope.parent = scope.$parent;

      scope.collectData = function (dirtyOnly, validOnly) {
        var form = this.subForm;
        if (validOnly && !form.$valid) return;
        var data = {};

        // save data

        for (var i=0;i<scope.formFields.length;i++) {
          var fieldName = scope.formFields[i];
          var field = form[fieldName];
          if (field && (!dirtyOnly || field.$dirty)) data[fieldName] = getval(field.$modelValue);
        }

        if (scope.form.pk) data['id'] = scope.form.pk;
        return [data];
      };

      scope.fieldChangeNotification = function(parent, field) {
        //var data = this.collectData(false, false);
        var data = scope.collectData(false, false);
        var model = parent.split('.');
        parent = model[2];
        model = model[0] + '/' + model[1];
        $http({
          method: 'POST',
          url: '/api/change/' + model + '/',
          params: {field: parent, subfield: field},
          headers: {'Content-Type': 'application/json'},
          data: data
        }).
        success(function (data) {
          if (data && data.data) {
              var form = data.data[0];
            for (var i in form) {
              scope.form.data[i] = form[i];
              if (scope.subForm) scope.subForm[i].$setDirty();
            }
          }
          //jQuery.extend($scope.form.item, data.values);
        });
      };
    },
    template: function (el, attrs) {
      el.find('field').each(function () {
        var field = $(this).attr('name');
        if (field) fields.push(field);
      });
      var html = el.html();
      var nm = attrs.contentField.split('.')[2];
      html = '<div class="sub-form sub-form-hidden row" name="' + nm + '" content-field="' + attrs.contentField +
          '">' + html + '</div>';
      return html;
    }
  }
});



ui.directive('grid', function ($compile, $http) {
  var formTempl, fields = [];
  return {
    restrict: 'E',
    replace: true,
    priority: 0,
    scope: {},
    link: function (scope, el, attrs) {
      var contentField = attrs.contentField;
      var fname = contentField.split('.');
      var url = '/api/content/' + fname[0] + '/' + fname[1] + '/';
      var gname = attrs.contentField.split('.')[2];
      var parentForm = scope.$parent.form;
      scope.form = {};
      scope._counters = [];

      scope.gridAddItem = function () {
        scope.form.pk = null;
        scope.form._data = {};
        scope.form.data = {};
        var modal = scope.showDialog();
        modal.modal();
      };

      scope.gridItemClick = function (obj) {
        scope.form.pk = obj.id;
        scope.form._data = obj;
        var modal = scope.showDialog();
        if (obj.__row__)
          scope.form.data = obj.__row__.data;
        else if (obj.id) {
          var params = {id: obj.id, mode: 'subform', field: gname, fields: scope.formFields};
          $http({
            method: 'GET',
            url: url,
            params: params
          }).success(function (data) {
            scope.form.data = data.items[0];
            if (!obj.__row__) {
              obj.__row__ = { op: 'update', data: scope.form.data, name: gname, _modifiedFields: [] };
              obj.__row__.id = scope.form.data.id;
            }
          }.bind(true));
        }
        modal.modal();
      };

      var refreshCounters = function () {
        var n = scope.$parent._counters['form.data.' + gname];
        if (n) for (var i=0;i< n.length;i++) n[i]();
      };

      scope.submitItem = function () {
        var modal = el.find('.modal').last();
        var data, cols, row;
        if (scope.form._data && (scope.items.indexOf(scope.form._data) > -1)) {
          data = scope.form._data;
          cols = data.__row__.data;
          row = data.__row__;
        } else {
          cols = {};
          row = { op: 'create', data: cols, name: gname, _modifiedFields: [] };
          data = { __row__: row };
        }
        for (var i=0;i<scope.formFields.length;i++) {
          var f = scope.formFields[i];
          if (f) {
            var v = scope.form.data[f];
            var fld = scope.subForm[f];
            if (fld.$dirty) row._modifiedFields.push(f);
            if (v instanceof Array) {
              cols[f] = v;
              data[f] = v[1];
            } else if ((typeof(v) === 'object') && v) {
              data[f] = v.text;
              cols[f] = v;
            } else cols[f] = data[f] = v;
          }
        }
        if (scope.items.indexOf(data) === -1) scope.items.push(data);
        parentForm.addSubItem(row);
        modal.modal('hide');

        scope.$parent.form.data[gname] = scope.items;
        refreshCounters();
      };

      scope.deleteItem = function (idx) {
        if (confirm(katrid.gettext('Confirm delete record?'))) {
          var data = scope.items[idx];
          var row = data.__row__;
          if (row && row.id) {
            row.op = 'delete';
            parentForm.addSubItem(row);
          } else if (data.id) {
            if (!angular.isDefined(row)) row = { id: data.id, name: gname, op: 'delete' };
            parentForm.addSubItem(row);
          } else parentForm.removeSubItem(row);
          scope.items.splice(idx, 1);
          refreshCounters();
        }
      };

      scope.showDialog = function () {
        var lbl = attrs.label;
        var elHtml = '<div class="modal fade" role="dialog">' +
            '<div class="modal-dialog modal-lg">' +
            '<div class="modal-content"><form name="subForm" ng-submit="submitItem()" novalidate>' +
            '<div class="modal-header">' +
            '<button type="button" class="close" data-dismiss="modal">&times;</button><h4 class="modal-title">' + lbl + ': <span>{{ form.data.__str__ }}</span></h4></div>' +
            '<div class="modal-body">' + formTempl + '</div>' +
            '<div class="modal-footer">' +
            '<button type="submit" class="btn btn-danger">' + katrid.gettext('Save') + '</button>' +
            '<button type="button" class="btn btn-default" data-dismiss="modal">' + katrid.gettext('Cancel') + '</button>' +
            '</div></form></div></div></div>';
        elHtml = angular.element(elHtml);
        elHtml = $compile(elHtml)(scope);
        el.append(elHtml);
        var frm = elHtml.find('.sub-form');
        frm.removeClass('sub-form-hidden');
        frm.addClass('sub-form-visible');
        var modal = el.find('.modal').last();
        //scope.gridItem = null;
        //frm.appendTo(modal.find('.modal-body').first());
        modal.on('hide.bs.modal', function () {
          modal.remove();
        });
        return elHtml;
      };

      var masterChange = function (masterKey) {
        if (parentForm.pk) {
          var params = {
            field: fname[2],
            fields: fields,
            mode: 'grid',
            id: parentForm.pk
          };
          $http({
            url: url,
            params: params
          }).success(function (data) {
            scope.items = data.items;
            scope.$parent.form.data[attrs['name']] = scope.items;
          }.bind(true));
        } else {
          console.log('init grid');
          scope.items = [];
          if (scope.$parent.form.data) scope.$parent.form.data[attrs['name']] = scope.items;
        }
      };

      scope.dataset = {name: gname, deleted: [], inserted: [], updated: []};
      //parentForm.grids[gname] = self;

      scope.$parent.$watch(parentForm.pk, function (value) {
        masterChange(value);
      });

    },
    template: function (tElement, tAttrs) {
      var th = '';
      var td = '';
      var cols = tElement.find('list').children();
      var fld = tAttrs.contentField;
      for (var i = 0; i < cols.length; i++) {
        var col = $(cols[i]);
        var css = col.attr('class');
        var tp = col.attr('type');
        if (!css) css = tp ? ' class="' + tp + '"' : '';
        else css = ' class="' + css + '"';
        var lbl = col.attr('label');
        if (!lbl) lbl = '';
        var nm = col.attr('name');
        var fmt = col.attr('format');

        modelField = 'item.' + nm;

        switch (tp) {
          case 'date':
            modelField = '(' + modelField + '|';
            if (fmt) modelField += fmt;
            else modelField += "date:'shortDate'";
            modelField += ')';
            break;
          case 'datetime':
            modelField = '(' + modelField + '|';
            if (fmt) modelField += fmt;
            else modelField += "date:'short'";
            modelField += ')';
            break;
          case 'decimal':
            modelField = '(' + modelField + '|';
            if (fmt) modelField += fmt;
            else modelField += 'number:2';
            modelField += ')';
            break;
        }

        th += '<th' + css + '>' + col.attr('label') + '</th>';
        td += '<td ' + css + ' ng-click="gridItemClick(item)" ng-bind="' + modelField + '"></td>';
        fields.push(nm);
      }
      th += '<th class="data-grid-col-remove"><span></span></th>';
      td += '<td class="data-grid-col-remove" ng-click="deleteItem($index)" title="' + katrid.gettext('Remove item') + '"><i class="fa fa-remove"></i></td>';

      var gridItems = 'item in items';
      formTempl = tElement.find('sub-form').prop('outerHTML');

      var nhtml = '<div class="data-grid" data-grid="' + fld + '">' +
          '<table class="table table-hover table-bordered table-striped table-condensed">' +
          '<thead>' +
          '<tr>' + th +
          '</tr></thead>' +
          '<tfoot><tr><td colspan="' + (cols.length + 1) + '">' +
          '<button type="button" class="btn btn-default btn-xs" ng-click="gridAddItem()">' + katrid.gettext('Add') + '</button>' +
          '</td></tr></tfoot>' +
          '<tbody>' +
          '<tr ng-repeat="' + gridItems + '" class="table-row-clickable">' +
          td +
          '</tr></tbody></table>' +
          '</div>';
      return nhtml;
    }
  }
});


ui.directive('uiSelect', function ($location) {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function (scope, element, attrs, controller) {
      var multiple = attrs.multiple;
      var allowCreate = false;
      var fname = attrs.uiSelect.split('.');
      var m = fname[0] + '.' + fname[1];
      var f = fname[2];
      var cfg = {
        ajax: {
          url: '/api/content/' + fname[0] + '/' + fname[1] + '/',
          dataType: 'json',
          quietMillis: 500,
          data: function (term, page) {
            return {
              mode: 'lookup',
              field: f,
              q: term,
              t: 1,
              p: page - 1
            }
          },
          results: function (data, page) {
            data = data.items;
            var more = (page * 10) < data.count;
            if (!multiple && (page === 1)) {
              data.splice(0, 0, {id: null, text: '---------'});
            }
            //data.push({id: {}, text: '<i>Search more...</i>'});
            if (allowCreate && !more) data.push({id: {}, text: '<i>Create new...</i>'});
            return {results: data, more: more};
          }
        },
        escapeMarkup: function (m) {
          return m;
        },
        initSelection: function (element, callback) {
          var v = controller.$modelValue;
          if (v) {
            if (multiple) {
              var values = [];
              for (var i = 0; i < v.length; i++) values.push({id: v[i][0], text: v[i][1]});
              callback(values);
            }
            else callback({id: v[0], text: v[1]});
          }
        }
      };
      if (multiple) cfg['multiple'] = true;
      var el = element.select2(cfg);
      element.on('$destroy', function () {
        $('.select2-hidden-accessible').remove();
        $('.select2-drop').remove();
        $('.select2-drop-mask').remove();
      });
      el.on('change', function (e) {
        var v = el.select2('data');
        controller.$setDirty();
        if (v) controller.$viewValue = v;
        scope.$apply();
      });

      controller.$render = function () {
        if (controller.$viewValue)
          element.select2('val', controller.$viewValue);
      };
    }
  }
});

ui.directive('ngEnter', function () {
  return function (scope, element, attrs) {
    element.bind("keydown keypress", function (event) {
      if (event.which === 13) {
        event.preventDefault();
        scope.$apply(function () {
          scope.$eval(attrs.ngEnter);
        });
      }
    });
  };
});

ui.directive('decimal', function ($filter) {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function (scope, element, attrs, controller) {

      var precision = attrs.precision || 2;

      //            $(function() {
      var thousands = attrs.uiMoneyThousands || ".";
      var decimal = attrs.uiMoneyDecimal || ",";
      var symbol = attrs.uiMoneySymbol;
      var negative = attrs.uiMoneyNegative || true;
      var el = element.maskMoney({
        symbol: symbol,
        thousands: thousands,
        decimal: decimal,
        precision: precision,
        allowNegative: negative,
        allowZero: true
      }).
      bind('keyup blur', function (event) {
            controller.$setViewValue(element.val().replace(RegExp('\\' + thousands, 'g'), '').replace(RegExp('\\' + decimal, 'g'), '.'));
            controller.$modelValue = parseFloat(element.val().replace(RegExp('\\' + thousands, 'g'), '').replace(RegExp('\\' + decimal, 'g'), '.'));
            scope.$apply();
          }
      );
      //            });

      controller.$render = function () {
        if (controller.$viewValue) element.val($filter('number')(controller.$viewValue, precision));
        else element.val('');
      };

    }
  }
});

ui.directive('uiDatepicker', function ($location) {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function (scope, element, attrs, controller) {
      var el = element.datepicker({
        dateFormat: 'dd/mm/yy',
        prevText: '<i class="fa fa-chevron-left"></i>',
        nextText: '<i class="fa fa-chevron-right"></i>'
      });

      function updateModelValue() {
        // save date in the correct ISO format
        if (controller.$modelValue && !(controller.$modelValue instanceof Date)) controller.$setViewValue(el.datepicker('getDate').toISOString().split('T')[0]);
        else if (controller.$modelValue && (controller.$modelValue instanceof Date)) controller.$setViewValue(el.datepicker('getDate').toISOString().split('T')[0]);
      }

      scope.$watch(attrs.ngModel, updateModelValue);

      el = el.mask('00/00/0000');

      controller.$render = function () {
        if (controller.$modelValue instanceof Date) {
          el.datepicker('setDate', controller.$modelValue);
        } else if (controller.$modelValue) {
          var dt = new Date(controller.$viewValue.split(/\-|\s/));
          el.datepicker('setDate', dt);
        }
      };

      el.on('change', function (evt) {
        var s = el.val();
        if (s.length === 5) {
          var dt = new Date();
          el.datepicker('setDate', s + '/' + dt.getFullYear().toString());
        }
      });

    }
  }
});

ui.directive('uiDatetimepicker', function ($location) {
  return {
    restrict: 'A',
    require: 'ngModel',
    link: function (scope, element, attrs, controller) {
      var el = element.datepicker({
        dateFormat: 'dd/mm/yy',
        prevText: '<i class="fa fa-chevron-left"></i>',
        nextText: '<i class="fa fa-chevron-right"></i>'
      });

      function updateModelValue() {
        // save date in the correct ISO format
        if (controller.$modelValue && !(controller.$modelValue instanceof Date)) controller.$setViewValue(el.datepicker('getDate').toISOString().split('T')[0]);
        else if (controller.$modelValue && (controller.$modelValue instanceof Date)) controller.$setViewValue(el.datepicker('getDate').toISOString().split('T')[0]);
      }

      scope.$watch(attrs.ngModel, updateModelValue);

      el = el.mask('00/00/0000 00:00');

      controller.$render = function () {
        if (controller.$modelValue instanceof Date) {
          el.datepicker('setDate', controller.$modelValue);
        } else if (controller.$modelValue) {
          var dt = new Date(controller.$viewValue.split(/\-|\s/));
          el.datepicker('setDate', dt);
        }
      };

      el.on('change', function (evt) {
        var s = el.val();
        if (s.length === 5) {
          var dt = new Date();
          el.datepicker('setDate', s + '/' + dt.getFullYear().toString());
        }
      });

    }
  }
});

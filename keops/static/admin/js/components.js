var ui = angular.module('ui.erp', []);

var _keopsWidgetCount = 0;

ui.directive('field', function ($compile) {
    return {
        restrict: 'E',
        replace: true,
        transclude: false,
        template: function(element, attrs) {
            var html = pre = pos = cols = icon = cls = fieldAttrs = '';
            var lbl = null;
            var tp = 'text';
            _keopsWidgetCount++;
            var widgetId = 'k-input-' + _keopsWidgetCount.toString();
            for (var attr in attrs) {
                if (attr === 'label') lbl = attrs.label;
                else if (attr === 'cols') cols = attrs.cols;
                else if (attr === 'type') tp = attrs.type;
                else if (attr === 'icon') icon = '<i class="' + attrs.icon + '"></i>';
                else if (attr === 'mask') fieldAttrs += ' ui-mask="' + attrs.mask + '"';
                else if (attr === 'class') cls = attrs.class;
                else if (attr === 'calcExpression') fieldAttrs += ' ng-bind="' + attrs.calcExpression + '"';
                else if ((attr === 'maxlength') && (attrs.mask)) {
                    attrs.maxlength = '';
                    fieldAttrs += ' ' + attr +'="' + attrs[attr] + '"';
                }
                else if (attr === 'helpText') {
                    if (attrs.type === 'checkbox') {
                        pos += attrs.helpText;
                    } else {
                        pre += '<i class="icon-append fa fa-question-circle"></i>';
                        pos += '<b class="tooltip tooltip-top-right"><i class="fa fa-warning txt-color-teal"></i> ' + attrs.helpText + ' </b>';
                    }
                }
                else if (attr[0] !== '$') fieldAttrs += ' ' + attr +'="' + attrs[attr] + '"';
            }
            attrs.class = '';
            attrs.ngBind = null;
            //attrs.label = null;
            delete attrs.cols;
            var nm = attrs.ngModel;
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
                if (icon) { pre += '<div class="input-group"><span class="input-group-addon">' + icon + '</span>'; pos = '</div>' + pos; }
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
                html = '<input type="text" ' + fieldAttrs + ' ui-select="' + attrs.contentField + '" style="width: 100%;" />';
            } else if (tp === 'date') {
                html = '<input class="form-control" type="text" ' + fieldAttrs + ' ui-datepicker ui-mask="99/99/9999"/>';
            } else if (tp === 'datetime') {
                html = '<input class="form-control" type="text" ' + fieldAttrs + ' ui-datepicker ui-mask="99/99/9999 99:99"/>';
            } else if (tp === 'grid') {
                html = '<grid ' + fieldAttrs + ' label="' + attrs.label + '">' + elHtml + '</grid>';
            } else if (tp === 'static') {
                html = '<p class="form-control-static ' + cls + '" ' + fieldAttrs + '>' + elHtml + '</p>';
            }
            if (lbl !== null) {
                lbl = '<label class="control-label" for="' + widgetId + '">' + lbl + '</label>';
            } else lbl = '';
            if (cols) {
                cols = 'class="col-sm-' + cols + '"';
            } else cols = "class='col-sm-12'";
            html = '<section ' + cols + '>' + lbl + html + '</section>';
            return html;
        }
    }
});


ui.directive('formset', function ($compile) {
    return {
        restrict: 'E',
        replace: true,
        template: function (tElement, attrs) {
            var html = tElement.html();
            var cols = tElement.children();
            var nm = attrs.name;
            var r = '<fieldset><div ng-init="form.loadFormset(\'' + nm + '\')">' +
                '<div class="row" ng-form="' + nm + '.{{$index}}" ng-repeat="subform in form.data.' + nm + '">' +
                html +
                '</div>' +
                '<div class="col-sm-12 margin-top-10"><button type="button" class="btn btn-default btn-sm" ng-click="form.data.' + nm + '.push({})">Adicionar</button></div>' +
                '</div></fieldset>';
            return r;
        }
    }
});


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
                $(group.attributes).each(function() { if (this.nodeName != 'class') _attrs += ' ' + this.nodeName + '="' + this.nodeValue + '"'; });
                var cls = $(group).attr('class');
                if (!cls) cls = 'btn-default';
                if (group.nodeName === 'ACTION') {
                    r += '<button class="btn btn-margin ' + cls + '"' + _attrs + '>' + group.innerHTML + '</button>';
                }
                else if (group.nodeName === 'ACTION-GROUP') {
                    r += '<div class="btn-group btn-margin"><a class="btn dropdown-toggle ' + cls + '"' + _attrs + ' data-toggle="dropdown" href="javascript:void(0);">' + $(group).attr('heading') + ' <span class="caret"></span></a><ul class="dropdown-menu" role="menu">';
                    var actions = $(group).children();
                    actions.each(function() {
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
        template: function(tElement, tAttrs) {
            var attrs = tAttrs;

            var children = tElement.children();
            var sparks = '';
            for (var i=0;i<children.length;i++) {
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
                for (i=0;i<cols.length;i++) {
                    var col = $(cols[i]);
                    if (col[0].nodeName === 'ACTIONS') { var actions = col[0]; continue; }
                    var css = col.attr('class');
                    if (!css) css = '';
                    else css = ' class="' + css + '"';
                    var lbl = col.attr('label');
                    if (!lbl) lbl = '';
                    th += '<th' + css + '>' + col.attr('label') + '</th>';
                    var modelField = 'item.' + col.attr('name');
                    switch (col.attr('type')) {
                        case 'date':
                            modelField = '(' + modelField + '|date)';
                            break;
                        case 'decimal':
                            modelField = '(' + modelField + '|number)';
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
                        '<button class="btn btn-default view-toolbutton" ng-show="selection" ng-click="list.deleteSelection();">' +
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
                        '<div><div class="col-sm-6"><p class="row" ng-show="selection === 1">' + katrid.gettext('1 Item selected.') + '</p>' +
                        '<p class="row" ng-show="selection > 1">' + katrid.gettext('{{ selection }} Items selected.') + '</p>' +
                        '<p class="row" ng-show="!selection">' + katrid.gettext('No selected data.') + '</p></div>' +
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

var _subInsert = function(dataSet, obj) {
    if (!(obj in dataSet.inserted)) dataSet.inserted.push(obj);
};

var _subDelete = function(dataSet, obj) {
    if (!(obj in dataSet.deleted)) dataSet.deleted.push(obj);
};

var _subUpdate = function(dataSet, obj) {
    if (!(obj in dataSet.updated)) dataSet.inserted.push(obj);
};

ui.directive('subForm', function () {
    var fields = [];
    return {
        restrict: 'E',
        replace: true,
        link: function (scope, el) {
            scope.formFields = fields;
        },
        template: function (el, attrs) {
            el.find('field').each(function() {
                var field = $(this).attr('name');
                fields.push(field);
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
        scope: {},
        link: function (scope, el, attrs) {
            var contentField = attrs.contentfield;
            var fname = contentField.split('.');
            var url = '/api/content/' + fname[0] + '/' + fname[1] + '/';
            var parentForm = scope.$parent.form;
            scope.form = {};

            scope.gridAddItem = function () {
                var modal = scope.showDialog();
                modal.modal();
            };

            scope.showDialog = function () {
                var lbl = attrs.label;
                var elHtml = '<div class="modal fade" role="dialog">' +
                    '<div class="modal-dialog modal-lg">' +
                    '<div class="modal-content">' +
                    '<div class="modal-header">' +
                    '<button type="button" class="close" data-dismiss="modal">&times;</button><h4 class="modal-title">' + lbl +  ': <span>{{ form.data.__str__ }}</span></h4></div>' +
                    '<div class="modal-body">' + formTempl + '</div>' +
                    '<div class="modal-footer">' +
                    '<button type="button" class="btn btn-danger" data-dismiss="modal">Save</button>' +
                    '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>' +
                    '</div></div></div></div>';
                elHtml = angular.element(elHtml);
                el.append(elHtml);
                $compile(elHtml)(scope);
                var frm = elHtml.find('.sub-form');
                frm.removeClass('sub-form-hidden');
                frm.addClass('sub-form-visible');
                //var modal = $('.modal').last();
                //scope.gridItem = null;
                //frm.appendTo(modal.find('.modal-body').first());
                modal.on('hide.bs.modal', function () {
                    modal.remove();
                });
                return elHtml;
            };

            scope.gridItemClick = function (obj) {
                scope.form.pk = obj.id;
                var modal = scope.showDialog();

                var params = {id: obj.id, mode: 'subform', field: fname[2], fields: scope.formFields};
                $http({
                    method: 'GET',
                    url: url,
                    params: params
                }).success(function (data) {
                    scope.form.data = data.items[0];
                    modal.modal();
                }.bind(true));
            };

            var masterChange = function (masterKey) {
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
                }.bind(true));
            };

            var gname = attrs.contentfield.split('.')[2];
            scope.dataset = {name: gname, deleted: [], inserted: [], updated: []};
            //parentForm.grids[gname] = self;

            scope.$parent.$watch(parentForm.pk, function(value) {
                masterChange(value);
            });
        },
        template: function(tElement, tAttrs) {
            var th = '';
            var td = '';
            var cols = tElement.find('list').children();
            var fld = tAttrs.contentField;
            for (var i=0;i<cols.length;i++) {
                var col = $(cols[i]);
                var css = col.attr('class');
                if (!css) css = '';
                else css = ' class="' + css + '"';
                var lbl = col.attr('label');
                if (!lbl) lbl = '';
                var nm = col.attr('name');
                th += '<th' + css + '>' + col.attr('label') + '</th>';
                td += '<td ' + css + ' ng-click="gridItemClick(item)" ng-bind="item.' + nm + '"></td>';
                fields.push(nm);
            }

            var gridItems = 'item in items';
            formTempl = tElement.find('sub-form').prop('outerHTML');

            var nhtml = '<div class="data-grid" data-grid="' + fld + '">' +
                '<button class="btn btn-default btn-xs" ng-click="gridAddItem()">Add</button>' +
                '<table class="table table-hover table-bordered table-striped table-condensed">' +
                '<thead>' +
                '<tr>' + th +
                '</tr></thead>' +
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
        require : 'ngModel',
        link: function(scope, element, attrs, controller) {
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
                        return { results: data, more: more };
                    }
                },
                escapeMarkup: function(m) { return m; },
                initSelection: function (element, callback) {
                    var v = controller.$modelValue;
                    if (v) {
                        if (multiple) {
                            console.log(v);
                            var values = [];
                            for (var i=0;i<v.length;i++) values.push({id: v[i][0], text: v[i][1]});
                            callback(values);
                        }
                        else
                            callback({id: v[0], text: v[1]})
                    }
                }
            };
            if (multiple) cfg['multiple'] = true;
            var el = element.select2(cfg);
            element.on('$destroy', function() {
                $('.select2-hidden-accessible').remove();
                $('.select2-drop').remove();
                $('.select2-drop-mask').remove();
            });
            el.on('change', function(e) {
                controller.$setDirty();
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
            var el = element.maskMoney({ symbol: symbol, thousands: thousands, decimal: decimal, precision: precision, allowNegative: negative, allowZero: true }).
            bind('keyup blur', function (event) {
                controller.$setViewValue(element.val().replace(RegExp('\\' + thousands, 'g'), '').replace(RegExp('\\' + decimal, 'g'), '.'));
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
        require : 'ngModel',
        priority: 1,
        link: function(scope, element, attrs, controller) {
            var el = element.datepicker({
                dateFormat: 'dd/mm/yy',
                prevText: '<i class="fa fa-chevron-left"></i>',
			    nextText: '<i class="fa fa-chevron-right"></i>'
            });

            controller.$render = function () {
                if (controller.$viewValue) {
                    var dt = new Date(controller.$viewValue.split(/\-|\s/));
                    element.val(dt.toLocaleDateString('pt-br'));
                }
            };

            element.on('change', function (v) {
                var val = $(this).val();
                controller.$viewValue = new Date().toLocaleString();
            });

        }
    }
});

ui.directive('uiMask', function ($location) {
    return {
        restrict: 'A',
        link: function(scope, element, attrs, controller) {
            var el = element.mask(attrs.uiMask);
        }
    }
});

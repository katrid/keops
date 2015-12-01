var ui = angular.module('ui.erp', []);

ui.directive('field', function ($compile) {
    return {
        restrict: 'E',
        replace: true,
        template: function(element, attrs) {
            var html = pre = pos = lbl = cols = fieldAttrs = '';
            var tp = 'text';
            for (var attr in attrs) {
                if (attr === 'label') lbl = attrs.label;
                else if (attr === 'cols') cols = attrs.cols;
                else if (attr === 'type') tp = attrs.type;
                else if (attr === 'icon') pre = '<i class="icon-prepend ' + attrs.icon + '"></i>';
                else if (attr === 'mask') fieldAttrs += ' ui-mask="' + attrs.mask + '"';
                else if (attr === 'helpText') {
                    pre += '<i class="icon-append fa fa-question-circle"></i>';
                    pos += '<b class="tooltip tooltip-top-right"><i class="fa fa-warning txt-color-teal"></i> ' + attrs.helpText + ' </b>';
                }
                else if (attr[0] !== '$') fieldAttrs += ' ' + attr +'="' + attrs[attr] + '"';
            }
            var nm = attrs.ngModel;
            if (!nm) {
                nm = 'form.data.' + attrs.name;
                fieldAttrs += ' ng-model="' + nm + '"';
            }
            if (nm) {
                var _nm = nm.split('.');
                var elname = _nm[_nm.length - 1];
                if (!attrs.name) fieldAttrs += ' name="' + elname + '"';
                if (!attrs.id) fieldAttrs += ' id="id_' + elname + '"';
            }
            var el = $(element[0]);
            //if ((tp === "decimal") || (tp === "int")) cls = 'text-right';
            if (tp === "decimal") {
                html = '<label class="input">' + pre + '<input type="text" decimal="decimal" ' + fieldAttrs + '>' + pos + el.html() + '</label>';
            } else if (tp === "int") {
                html = '<label class="input">' + pre + '<input type="text" decimal="decimal" precision="0" ' + fieldAttrs + '>' + pos + el.html() + '</label>';
            } else if (tp === "text") {
                html = pre + '<input class="form-control" type="text" ' + fieldAttrs + '/>' + pos + el.html();
            } else if (tp === "select") {
                html = '<select class="form-control" ' + fieldAttrs + '>' + el.html() + '</select>';
            } else if (tp === "checkbox") {
                html = '<label class="checkbox"><input type="checkbox" ' + fieldAttrs + '><i></i>' + el.html() + '</label>';
            } else if (tp === "textarea") {
                html = pre + '<textarea class="form-control" ' + fieldAttrs + '>' + el.html() + '</textarea>' + pos;
            } else if (tp === 'lookup') {
                if (attrs.multiple) fieldAttrs += ' multiple';
                html = '<input type="text" ' + fieldAttrs + ' ui-select="' + attrs.contentField + '" style="width: 100%;" />';
            } else if (tp === 'date') {
                html = '<input class="form-control" type="text" ' + fieldAttrs + ' ui-datepicker ui-mask="99/99/9999"/>';
            } else if (tp === 'grid') {
                html = '<grid ' + fieldAttrs + ' label="' + attrs.label + '">' + el.html() + '</grid>';
            }
            if (lbl) {
                lbl = '<label class="control-label" for="id_' + elname + '">' + lbl + '</label>';
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
            var html = tElement.html();
            var node = tElement[0].nodeName;
            if (node === 'LIST') {
                var cols = tElement.children();
                var th = '<th class="checkbox-action"><input id="action-toggle" type="checkbox" ng-click="toggleCheckAll();" /></th>';
                var td = '<td><input type="checkbox" class="action-select" ng-click="selectItem(item)" /></td>';
                for (var i=0;i<cols.length;i++) {
                    var col = $(cols[i]);
                    if (col[0].nodeName === 'ACTIONS') { var actions = col[0]; continue; }
                    var css = col.attr('class');
                    if (!css) css = '';
                    else css = ' class="' + css + '"';
                    var lbl = col.attr('label');
                    if (!lbl) lbl = '';
                    th += '<th' + css + '>' + col.attr('label') + '</th>';
                    td += '<td ' + css + ' ng-click="list.itemClick(item)" ng-bind="item.' + col.attr('name') + '"></td>';
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
                        '<input id="search-fld" type="text" placeholder="Busca rápida" ng-model="queryField" ng-enter="list.query(queryField)">' +
                        '<button type="button" ng-click="list.query(queryField)"><i class="fa fa-search"></i></button><a href="javascript:void(0);" id="cancel-search-js" title="Cancel Search"><i class="fa fa-times"></i></a></form>' +
                        '</div>' +
                        '<div class="col-sm-12 view-toolbar">' +
                        '<button class="btn btn-danger view-toolbutton" ng-click="showForm()"> Criar </button>' +
                        '<button class="btn btn-default view-toolbutton" ng-show="selection" ng-click="list.deleteSelection();">' +
                        '<span class="glyphicon glyphicon-trash"></span> Excluir</button>' +
                        //actions.outerHTML +
                        '<div class="btn-group view-toolbutton">' +
                        '<a class="btn btn-default dropdown-toggle" data-toggle="dropdown" href="javascript:void(0);">Ações <span class="caret"></span></a>' +
                        '<ul class="dropdown-menu"><li><a href="javascript:void(0);">Exportar Dados</a></li></ul>' +
                        '</div>' +
                        '<div class="btn-group pull-right view-mode-buttons"><button type="button" class="btn btn-default active" title="Ir para pesquisa"><i class="fa fa-table"></i></button><button type="button" class="btn btn-default" title="Exibir formulário" ng-click="showForm(list.items[0].pk)"><i class="fa fa-edit"></i></button></div>' +
                        '</div>' +
                        '</div></div>' +
                        '<div class="row"><article class="col-sm-12">' +
                        '<div>' +
                        '<div role="content">' +
                        '<div class="list-content">' +
                        '<div><div class="col-sm-6"><p class="row" ng-show="selection === 1">{{ selection }} Item selecionado.</p>' +
                        '<p class="row" ng-show="selection > 1">{{ selection }} Itens selecionados.</p>' +
                        '<p class="row" ng-show="!selection">Nenhum item selecionado.</p></div>' +
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
                    '<div class="col-sm-12">' +
                    '<div class="pull-right nav-paginator" style="margin-top: 10px">' +
                    '<label class="nav-recno-info">1 / 1</label>' +
                    '<a class="btn btn-default"><i class="fa fa-chevron-left"></i></a>' +
                    '<a class="btn btn-default"><i class="fa fa-chevron-right"></i></a>' +
                    '</div>' +
                    '<h1 class="page-title txt-color-blueDark">' +
                    '<i class="fa-fw fa fa-pencil-square-o"></i>' + attrs.viewTitle + ' <span>/ {{ form.data.__str__ }}</span><span ng-show="!form.data.pk">&nbsp;</span></h1>' +
                    '</div><div class="col-sm-12 view-toolbar">' +
                    '<button type="button" class="btn btn-danger view-toolbutton" title="Salvar" ng-click="submit()">Salvar</button>' +
                    '<button ng-click="showList()" class="btn btn-default view-toolbutton">Cancelar</button>' +
                    '<div class="btn-group pull-right view-mode-buttons"><button type="button" class="btn btn-default" title="Ir para pesquisa" ng-click="showList()"><i class="fa fa-table"></i></button><button type="button" class="btn btn-default active" title="Exibir formulário"><i class="fa fa-edit"></i></button></div>' +
                    '</div></div>' +
                    '<div class="row">' +
                    '<div class="form-content"> ' +
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
    var fields = '';
    return {
        restrict: 'E',
        replace: true,
        link: function (scope, el) {
            scope.fields = fields;
        },
        template: function (el, attrs) {
            el.find('field').each(function() {
                var field = $(this).attr('name');
                if (fields) fields += ',' + field;
                else fields = field;
            });
            var html = el.html();
            var nm = attrs.contentField.split('.')[2];
            html = '<div class="sub-form sub-form-hidden" name="' + nm + '" content-field="' + attrs.contentField +
                '">' + html + '</div>';
            return html;
        }
    }
});

ui.directive('grid', function ($compile, $http) {
    var fields = '';
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

            scope.gridItemClick = function (obj) {
                scope.form.pk = obj.id;
                var frm = $compile(el.find('.sub-form').clone())(scope);
                frm.removeClass('sub-form-hidden');
                frm.addClass('sub-form-visible');
                var elHtml = '<div class="modal fade" role="dialog">' +
                    '<div class="modal-dialog">' +
                    '<div class="modal-content">' +
                    '<div class="modal-header">' +
                    '<button type="button" class="close" data-dismiss="modal">&times;</button><h4 class="modal-title">' + attrs.label +  '</h4></div>' +
                    '<div class="modal-body"></div>' +
                    '<div class="modal-footer">' +
                    '<button type="button" class="btn btn-danger" data-dismiss="modal">Save</button>' +
                    '<button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>' +
                    '</div></div></div></div>';
                el.append(elHtml);
                var modal = $('.modal').last();
                scope.gridItem = obj;
                frm.appendTo(modal.find('.modal-body').first());
                var params = {id: obj.id, mode: 'subform', field: fname[2], fields: scope.fields};
                modal.on('hide.bs.modal', function (){
                    modal.remove();
                });
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
                if (!fields) fields = nm;
                else fields += ',' + nm;
            }

            var gridItems = 'item in items';
            var subForm = tElement.find('sub-form').prop('outerHTML');

            var nhtml = '<div class="data-grid" data-grid="' + fld + '"><table class="table table-hover table-bordered table-striped table-condensed">' +
                '<thead>' +
                '<tr>' + th +
                '</tr></thead>' +
                '<tbody>' +
                '<tr ng-repeat="' + gridItems + '" class="table-row-clickable">' +
                td +
                '</tr></tbody></table>' +
                subForm +
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
                        if (allowCreate && !more) data.data.push({id: {}, text: '<b><i>' + 'Create new...' + '</i></b>'});
                        return { results: data, more: more };
                    }
                },
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

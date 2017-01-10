// Generated by CoffeeScript 1.10.0
(function() {
  var formCount, uiKatrid;

  uiKatrid = Katrid.uiKatrid;

  formCount = 0;

  uiKatrid.directive('field', function($compile) {
    var fieldType, widget;
    fieldType = null;
    widget = null;
    return {
      restrict: 'E',
      replace: true,
      link: function(scope, element, attrs, ctrl, transclude) {
        var att, cols, fcontrol, field, fieldAttrs, form, templ, tp, v;
        field = scope.view.fields[attrs.name];
        if (element.parent('list').length === 0) {
          element.removeAttr('name');
          widget = attrs.widget;
          if (!widget) {
            tp = field.type;
            if (tp === 'ForeignKey') {
              widget = tp;
            } else if (field.choices) {
              widget = 'SelectField';
            } else if (tp === 'TextField') {
              widget = 'TextareaField';
            } else if (tp === 'BooleanField') {
              widget = 'CheckBox';
            } else if (tp === 'DecimalField') {
              widget = 'DecimalField';
              cols = 3;
            } else if (tp === 'DateField') {
              widget = 'DateField';
              cols = 3;
            } else if (tp === 'DateTimeField') {
              widget = 'DateField';
              cols = 3;
            } else if (tp === 'IntegerField') {
              widget = 'TextField';
              cols = 3;
            } else if (tp === 'CharField') {
              widget = 'TextField';
              if (field.max_length && field.max_length < 30) {
                cols = 3;
              }
            } else if (tp === 'OneToManyField') {
              widget = tp;
              cols = 12;
            } else if (tp === 'ManyToManyField') {
              widget = tp;
            } else {
              widget = 'TextField';
            }
          }
          widget = new Katrid.UI.Widgets[widget];
          field = scope.view.fields[attrs.name];
          templ = ("<section class=\"section-field-" + attrs.name + " form-group\">") + widget.template(scope, element, attrs, field) + '</section>';
          templ = $compile(templ)(scope);
          element.replaceWith(templ);
          templ.addClass("col-md-" + (attrs.cols || cols || 6));
          fcontrol = templ.find('.form-field');
          if (fcontrol.length) {
            fcontrol = fcontrol[fcontrol.length - 1];
            form = templ.controller('form');
            ctrl = angular.element(fcontrol).data().$ngModelController;
            if (ctrl) {
              form.$addControl(ctrl);
            }
          }
          widget.link(scope, templ, fieldAttrs, $compile, field);
          fieldAttrs = {};
          for (att in attrs) {
            v = attrs[att];
            if (!(att.startsWith('field'))) {
              continue;
            }
            fieldAttrs[att] = v;
            element.removeAttr(att);
            attrs.$set(att);
          }
          return fieldAttrs.name = attrs.name;
        }
      }
    };
  });

  uiKatrid.directive('view', function() {
    return {
      restrict: 'E',
      template: function(element, attrs) {
        formCount++;
        return '';
      },
      link: function(scope, element, attrs) {
        if (scope.model) {
          element.attr('class', 'view-form-' + scope.model.name.replace(new RegExp('\.', 'g'), '-'));
          element.attr('id', 'katrid-form-' + formCount.toString());
          element.attr('model', scope.model);
          return element.attr('name', 'dataForm' + formCount.toString());
        }
      }
    };
  });

  uiKatrid.directive('list', function($compile, $http) {
    return {
      restrict: 'E',
      priority: 700,
      link: function(scope, element, attrs) {
        var html;
        console.log('im list', 1);
        html = Katrid.UI.Utils.Templates.renderList(scope, element, attrs);
        return element.replaceWith($compile(html)(scope));
      }
    };
  });

  uiKatrid.directive('ngSum', function() {
    return {
      restrict: 'A',
      priority: 9999,
      require: 'ngModel',
      link: function(scope, element, attrs, controller) {
        var field, nm, subField;
        nm = attrs.ngSum.split('.');
        field = nm[0];
        subField = nm[1];
        return scope.$watch('record.$' + field, function(newValue, oldValue) {
          var v;
          if (newValue && scope.record) {
            v = 0;
            scope.record[field].map((function(_this) {
              return function(obj) {
                return v += parseFloat(obj[subField]);
              };
            })(this));
            if (v.toString() !== controller.$modelValue) {
              controller.$setViewValue(v);
              controller.$render();
            }
          }
        });
      }
    };
  });

  uiKatrid.directive('grid', function($compile) {
    return {
      restrict: 'E',
      replace: true,
      scope: {},
      link: function(scope, element, attrs) {
        var field, masterChanged, p, renderDialog;
        field = scope.$parent.view.fields[attrs.name];
        scope.fieldName = attrs.name;
        scope.field = field;
        scope.records = [];
        scope.recordIndex = -1;
        scope._viewCache = {};
        scope._changeCount = 0;
        scope.dataSet = [];
        scope.parent = scope.$parent;
        scope.model = new Katrid.Services.Model(field.model);
        scope.dataSource = new Katrid.Data.DataSource(scope);
        p = scope.$parent;
        while (p) {
          if (p.dataSource) {
            scope.dataSource.setMasterSource(p.dataSource);
            break;
          }
          p = p.$parent;
        }
        scope.dataSource.fieldName = scope.fieldName;
        scope.gridDialog = null;
        scope.model.getViewInfo({
          view_type: 'list'
        }).done(function(res) {
          return scope.$apply(function() {
            var html;
            scope.view = res.result;
            html = Katrid.UI.Utils.Templates.renderGrid(scope, $(scope.view.content), attrs, 'openItem($index)');
            return element.replaceWith($compile(html)(scope));
          });
        });
        renderDialog = function() {
          var el, html;
          html = scope._viewCache.form.content;
          html = $(Katrid.UI.Utils.Templates.gridDialog().replace('<!-- view content -->', html));
          el = $compile(html)(scope);
          scope.formElement = el.find('form').first();
          scope.form = scope.formElement.controller('form');
          scope.gridDialog = el;
          el.modal('show');
          el.on('hidden.bs.modal', function() {
            scope.dataSource.setState(Katrid.Data.DataSourceState.browsing);
            el.remove();
            scope.gridDialog = null;
            return scope.recordIndex = -1;
          });
          return false;
        };
        scope.addItem = function() {
          scope.dataSource.newRecord();
          return scope.showDialog();
        };
        scope.openItem = function(index) {
          if (scope.parent.dataSource.changing) {
            scope.dataSource.editRecord();
          }
          return scope.showDialog(index);
        };
        scope.removeItem = function(idx) {
          return scope.records.splice(idx, 1);
        };
        scope.set = (function(_this) {
          return function(field, value) {
            scope.form[field].$setViewValue(value);
            scope.form[field].$render();
            return true;
          };
        })(this);
        scope.save = function() {
          var attr, data, rec, v;
          data = scope.dataSource.applyModifiedData(scope.form, scope.gridDialog, scope.record);
          if (scope.recordIndex > -1) {
            rec = scope.records[scope.recordIndex];
            for (attr in data) {
              v = data[attr];
              rec[attr] = v;
            }
          } else if (scope.recordIndex === -1) {
            scope.records.push(scope.record);
          }
          scope.gridDialog.modal('toggle');
          scope.parent.record['$' + scope.fieldName] = ++scope._changeCount;
          scope.parent.record[scope.fieldName] = scope.records;
        };
        scope.test = function(msg) {
          return console.log('msg', msg);
        };
        scope.showDialog = function(index) {
          var rec;
          if (index != null) {
            scope.recordIndex = index;
            if (!scope.dataSet[index]) {
              scope.dataSource.get(scope.records[index].id, 0).done(function(res) {
                if (res.ok) {
                  return scope.$apply(function() {
                    return scope.dataSet[index] = scope.record;
                  });
                }
              });
            }
            rec = scope.dataSet[index];
            scope.record = rec;
          } else {
            scope.recordIndex = -1;
          }
          if (scope._viewCache.form) {
            setTimeout(function() {
              return renderDialog();
            });
          } else {
            scope.model.getViewInfo({
              view_type: 'form'
            }).done(function(res) {
              if (res.ok) {
                scope._viewCache.form = res.result;
                return renderDialog();
              }
            });
          }
          return false;
        };
        masterChanged = function(key) {
          var data;
          data = {};
          data[field.field] = key;
          scope._changeCount = 0;
          scope.records = [];
          return scope.dataSource.search(data);
        };
        return scope.$parent.$watch('recordId', function(key) {
          return masterChanged(key);
        });
      }
    };
  });

  uiKatrid.directive('ngEnter', function() {
    return function(scope, element, attrs) {
      return element.bind("keydown keypress", function(event) {
        if (event.which === 13) {
          scope.$apply(function() {
            return scope.$eval(attrs.ngEnter);
          });
          return event.preventDefault();
        }
      });
    };
  });

  uiKatrid.directive('datepicker', function() {
    return {
      restrict: 'A',
      require: '?ngModel',
      link: function(scope, element, attrs, controller) {
        var el, updateModelValue;
        el = element.datepicker({
          format: Katrid.i18n.gettext('yyyy-mm-dd'),
          forceParse: false
        });
        updateModelValue = function() {
          console.log(controller.$modelValue, el.val());
          if (controller.$modelValue !== el.val()) {
            return el.val(controller.$modelValue);
          }
        };
        scope.$watch(attrs.ngModel, updateModelValue);
        el = el.mask('00/00/0000');
        controller.$render = function() {
          var dt;
          if (controller.$modelValue) {
            dt = new Date(controller.$modelValue);
            return el.datepicker('setDate', dt);
          }
        };
        return el.on('blur', function(evt) {
          var dt, s;
          s = el.val();
          if ((s.length === 5) || (s.length === 6)) {
            if (s.length === 6) {
              s = s.substr(0, 5);
            }
            dt = new Date();
            el.datepicker('setDate', s + '/' + dt.getFullYear().toString());
          }
          if ((s.length === 2) || (s.length === 3)) {
            if (s.length === 3) {
              s = s.substr(0, 2);
            }
            dt = new Date();
            return el.datepicker('setDate', new Date(dt.getFullYear(), dt.getMonth(), s));
          }
        });
      }
    };
  });

  uiKatrid.directive('ajaxChoices', function($location) {
    return {
      restrict: 'A',
      require: '?ngModel',
      link: function(scope, element, attrs, controller) {
        var cfg, el, multiple, serviceName;
        multiple = attrs.multiple;
        serviceName = attrs.ajaxChoices;
        cfg = {
          ajax: {
            url: serviceName,
            dataType: 'json',
            quietMillis: 500,
            data: function(term, page) {
              return {
                q: term,
                t: 1,
                p: page - 1,
                file: attrs.reportFile,
                sql_choices: attrs.sqlChoices
              };
            },
            results: function(data, page) {
              var more;
              console.log(data);
              data = data.items;
              more = (page * 10) < data.count;
              if (!multiple && (page === 1)) {
                data.splice(0, 0, {
                  id: null,
                  text: '---------'
                });
              }
              return {
                results: data,
                more: more
              };
            }
          },
          escapeMarkup: function(m) {
            return m;
          },
          initSelection: function(element, callback) {
            var i, j, len, v, values;
            v = controller.$modelValue;
            if (v) {
              if (multiple) {
                values = [];
                for (j = 0, len = v.length; j < len; j++) {
                  i = v[j];
                  values.push({
                    id: i[0],
                    text: i[1]
                  });
                }
                return callback(values);
              } else {
                return callback({
                  id: v[0],
                  text: v[1]
                });
              }
            }
          }
        };
        if (multiple) {
          cfg['multiple'] = true;
        }
        el = element.select2(cfg);
        element.on('$destroy', function() {
          $('.select2-hidden-accessible').remove();
          $('.select2-drop').remove();
          return $('.select2-drop-mask').remove();
        });
        el.on('change', function(e) {
          var v;
          v = el.select2('data');
          controller.$setDirty();
          if (v) {
            controller.$viewValue = v;
          }
          return scope.$apply();
        });
        return controller.$render = function() {
          if (controller.$viewValue) {
            return element.select2('val', controller.$viewValue);
          }
        };
      }
    };
  });

  uiKatrid.directive('decimal', function($filter) {
    return {
      restrict: 'A',
      require: 'ngModel',
      link: function(scope, element, attrs, controller) {
        var decimal, el, negative, precision, symbol, thousands;
        precision = attrs.precision || 2;
        thousands = attrs.uiMoneyThousands || ".";
        decimal = attrs.uiMoneyDecimal || ",";
        symbol = attrs.uiMoneySymbol;
        negative = attrs.uiMoneyNegative || true;
        el = element.maskMoney({
          symbol: symbol,
          thousands: thousands,
          decimal: decimal,
          precision: precision,
          allowNegative: negative,
          allowZero: true
        }).bind('keyup blur', function(event) {
          var newVal;
          newVal = element.maskMoney('unmasked')[0];
          if (newVal.toString() !== controller.$viewValue) {
            controller.$setViewValue(newVal);
            return scope.$apply();
          }
        });
        return controller.$render = function() {
          if (controller.$viewValue) {
            return element.val($filter('number')(controller.$viewValue, precision));
          } else {
            return element.val('');
          }
        };
      }
    };
  });

  Katrid.uiKatrid.directive('foreignkey', function() {
    return {
      restrict: 'A',
      require: 'ngModel',
      link: function(scope, el, attrs, controller) {
        var config, f, multiple, newItem, sel;
        f = scope.view.fields['model'];
        sel = el;
        el.addClass('form-field');
        newItem = function() {};
        config = {
          allowClear: true,
          ajax: {
            url: '/api/rpc/' + scope.model.name + '/get_field_choices/?args=' + attrs.name,
            data: function(term, page) {
              return {
                q: term
              };
            },
            results: function(data, page) {
              var item, msg, r;
              r = (function() {
                var j, len, ref, results;
                ref = data.result;
                results = [];
                for (j = 0, len = ref.length; j < len; j++) {
                  item = ref[j];
                  results.push({
                    id: item[0],
                    text: item[1]
                  });
                }
                return results;
              })();
              if (!multiple) {
                msg = Katrid.i18n.gettext('Create <i>"{0}"</i>...');
                if (sel.data('select2').search.val()) {
                  r.push({
                    id: newItem,
                    text: msg
                  });
                }
              }
              return {
                results: r
              };
            }
          },
          formatResult: function(state) {
            var s;
            s = sel.data('select2').search.val();
            if (state.id === newItem) {
              state.str = s;
              return '<strong>' + state.text.format(s) + '</strong>';
            }
            return state.text;
          },
          initSelection: function(el, cb) {
            var obj, v;
            v = controller.$modelValue;
            if (multiple) {
              v = (function() {
                var j, len, results;
                results = [];
                for (j = 0, len = v.length; j < len; j++) {
                  obj = v[j];
                  results.push({
                    id: obj[0],
                    text: obj[1]
                  });
                }
                return results;
              })();
              return cb(v);
            } else if (v) {
              return cb({
                id: v[0],
                text: v[1]
              });
            }
          }
        };
        multiple = attrs.multiple;
        if (multiple) {
          config['multiple'] = true;
        }
        sel = sel.select2(config);
        sel.on('change', function(e) {
          var obj, service, v;
          v = sel.select2('data');
          if (v.id === newItem) {
            service = new Katrid.Services.Model(scope.view.fields[attrs.name].model);
            return service.createName(v.str).then(function(res) {
              controller.$setDirty();
              controller.$setViewValue(res.result);
              return sel.select2('val', {
                id: res.result[0],
                text: res.result[1]
              });
            });
          } else if (v && multiple) {
            v = (function() {
              var j, len, results;
              results = [];
              for (j = 0, len = v.length; j < len; j++) {
                obj = v[j];
                results.push(obj.id);
              }
              return results;
            })();
            return controller.$setViewValue(v);
          } else {
            controller.$setDirty();
            if (v) {
              return controller.$setViewValue([v.id, v.text]);
            } else {
              return controller.$setViewValue(null);
            }
          }
        });
        return controller.$render = function() {
          var obj, v;
          if (multiple) {
            if (controller.$viewValue) {
              v = (function() {
                var j, len, ref, results;
                ref = controller.$viewValue;
                results = [];
                for (j = 0, len = ref.length; j < len; j++) {
                  obj = ref[j];
                  results.push(obj[0]);
                }
                return results;
              })();
              sel.select2('val', v);
            }
          }
          if (controller.$viewValue) {
            return sel.select2('val', controller.$viewValue[0]);
          } else {
            return sel.select2('val', null);
          }
        };
      }
    };
  });

  uiKatrid.directive('searchBox', function() {
    return {
      restrict: 'A',
      require: 'ngModel',
      link: function(scope, el, attrs, controller) {
        var cfg, fields, view;
        view = scope.views.search;
        fields = view.fields;
        cfg = {
          multiple: true,
          minimumInputLength: 1,
          formatSelection: (function(_this) {
            return function(obj, element) {
              if (obj.field) {
                element.append("<span class=\"search-icon\">" + obj.field.caption + "</span>: <i class=\"search-term\">" + obj.text + "</i>");
              } else if (obj.id.caption) {
                element.append("<span class=\"search-icon\">" + obj.id.caption + "</span>: <i class=\"search-term\">" + obj.text + "</i>");
              } else {
                element.append('<span class="fa fa-filter search-icon"></span><span class="search-term">' + obj.text + '</span>');
              }
            };
          })(this),
          id: function(obj) {
            if (obj.field) {
              return obj.field.name;
              return '<' + obj.field.name + ' ' + obj.id + '>';
            }
            return obj.id.name;
            return obj.id.name + '-' + obj.text;
          },
          formatResult: (function(_this) {
            return function(obj, element, query) {
              if (obj.id.type === 'ForeignKey') {
                return "> Pesquisar <i>" + obj.id.caption + "</i> por: <strong>" + obj.text + "</strong>";
              } else if (obj.field && obj.field.type === 'ForeignKey') {
                return obj.field.caption + ": <i>" + obj.text + "</i>";
              } else {
                return "Pesquisar <i>" + obj.id.caption + "</i> por: <strong>" + obj.text + "</strong>";
              }
            };
          })(this),
          query: (function(_this) {
            return function(options) {
              var f;
              if (options.field) {
                scope.model.getFieldChoices(options.field.name, options.term).done(function(res) {
                  var obj;
                  return options.callback({
                    results: (function() {
                      var j, len, ref, results;
                      ref = res.result;
                      results = [];
                      for (j = 0, len = ref.length; j < len; j++) {
                        obj = ref[j];
                        results.push({
                          id: obj[0],
                          text: obj[1],
                          field: options.field
                        });
                      }
                      return results;
                    })()
                  });
                });
                return;
              }
              options.callback({
                results: (function() {
                  var results;
                  results = [];
                  for (f in fields) {
                    results.push({
                      id: fields[f],
                      text: options.term
                    });
                  }
                  return results;
                })()
              });
            };
          })(this)
        };
        $(el).select2(cfg);
        el.on('change', (function(_this) {
          return function() {
            return controller.$setViewValue(el.select2('data'));
          };
        })(this));
        el.on('select2-selecting', (function(_this) {
          return function(e) {
            var v;
            if (e.choice.id.type === 'ForeignKey') {
              v = el.data('select2');
              v.opts.query({
                element: v.opts.element,
                term: v.search.val(),
                field: e.choice.id,
                callback: function(data) {
                  v.opts.populateResults.call(v, v.results, data.results, {
                    term: '',
                    page: null,
                    context: v.context
                  });
                  return v.postprocessResults(data, false, false);
                }
              });
              return e.preventDefault();
            }
          };
        })(this));
      }
    };
  });

  uiKatrid.controller('TabsetController', [
    '$scope', function($scope) {
      var ctrl, destroyed, tabs;
      ctrl = this;
      tabs = ctrl.tabs = $scope.tabs = [];
      ctrl.select = function(selectedTab) {
        angular.forEach(tabs, function(tab) {
          if (tab.active && tab !== selectedTab) {
            tab.active = false;
            tab.onDeselect();
          }
        });
        selectedTab.active = true;
        selectedTab.onSelect();
      };
      ctrl.addTab = function(tab) {
        tabs.push(tab);
        if (tabs.length === 1) {
          tab.active = true;
        } else if (tab.active) {
          ctrl.select(tab);
        }
      };
      ctrl.removeTab = function(tab) {
        var index, newActiveIndex;
        index = tabs.indexOf(tab);
        if (tab.active && tabs.length > 1 && !destroyed) {
          newActiveIndex = index === tabs.length - 1 ? index - 1 : index + 1;
          ctrl.select(tabs[newActiveIndex]);
        }
        tabs.splice(index, 1);
      };
      destroyed = void 0;
      $scope.$on('$destroy', function() {
        destroyed = true;
      });
    }
  ]);

  uiKatrid.directive('tabset', function() {
    return {
      restrict: 'EA',
      transclude: true,
      replace: true,
      scope: {
        type: '@'
      },
      controller: 'TabsetController',
      template: "<div><div class=\"clearfix\"></div>\n" + "  <ul class=\"nav nav-{{type || 'tabs'}}\" ng-class=\"{'nav-stacked': vertical, 'nav-justified': justified}\" ng-transclude></ul>\n" + "  <div class=\"tab-content\">\n" + "    <div class=\"tab-pane\" \n" + "         ng-repeat=\"tab in tabs\" \n" + "         ng-class=\"{active: tab.active}\"\n" + "         tab-content-transclude=\"tab\">\n" + "    </div>\n" + "  </div>\n" + "</div>\n",
      link: function(scope, element, attrs) {
        scope.vertical = angular.isDefined(attrs.vertical) ? scope.$parent.$eval(attrs.vertical) : false;
        return scope.justified = angular.isDefined(attrs.justified) ? scope.$parent.$eval(attrs.justified) : false;
      }
    };
  });

  uiKatrid.directive('tab', [
    '$parse', function($parse) {
      return {
        require: '^tabset',
        restrict: 'EA',
        replace: true,
        template: "<li ng-class=\"{active: active, disabled: disabled}\">\n" + "  <a href ng-click=\"select()\" tab-heading-transclude>{{heading}}</a>\n" + "</li>\n",
        transclude: true,
        scope: {
          active: '=?',
          heading: '@',
          onSelect: '&select',
          onDeselect: '&deselect'
        },
        controller: function() {},
        compile: function(elm, attrs, transclude) {
          return function(scope, elm, attrs, tabsetCtrl) {
            scope.$watch('active', function(active) {
              if (active) {
                tabsetCtrl.select(scope);
              }
            });
            scope.disabled = false;
            if (attrs.disabled) {
              scope.$parent.$watch($parse(attrs.disabled), function(value) {
                scope.disabled = !!value;
              });
            }
            scope.select = function() {
              if (!scope.disabled) {
                scope.active = true;
              }
            };
            tabsetCtrl.addTab(scope);
            scope.$on('$destroy', function() {
              tabsetCtrl.removeTab(scope);
            });
            scope.$transcludeFn = transclude;
          };
        }
      };
    }
  ]);

  uiKatrid.directive('tabHeadingTransclude', [
    function() {
      return {
        restrict: 'A',
        require: '^tab',
        link: function(scope, elm, attrs, tabCtrl) {
          scope.$watch('headingElement', function(heading) {
            if (heading) {
              elm.html('');
              elm.append(heading);
            }
          });
        }
      };
    }
  ]);

  uiKatrid.directive('tabContentTransclude', function() {
    var isTabHeading;
    isTabHeading = function(node) {
      return node.tagName && (node.hasAttribute('tab-heading') || node.hasAttribute('data-tab-heading') || node.tagName.toLowerCase() === 'tab-heading' || node.tagName.toLowerCase() === 'data-tab-heading');
    };
    return {
      restrict: 'A',
      require: '^tabset',
      link: function(scope, elm, attrs) {
        var tab;
        tab = scope.$eval(attrs.tabContentTransclude);
        tab.$transcludeFn(tab.$parent, function(contents) {
          angular.forEach(contents, function(node) {
            if (isTabHeading(node)) {
              tab.headingElement = node;
            } else {
              elm.append(node);
            }
          });
        });
      }
    };
  });

  uiKatrid.filter('m2m', function() {
    return function(input) {
      var obj;
      if (_.isArray(input)) {
        return ((function() {
          var j, len, results;
          results = [];
          for (j = 0, len = input.length; j < len; j++) {
            obj = input[j];
            results.push(obj[1]);
          }
          return results;
        })()).join(', ');
      }
    };
  });

}).call(this);

//# sourceMappingURL=components.js.map

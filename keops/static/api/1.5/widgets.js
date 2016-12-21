// Generated by CoffeeScript 1.10.0
(function() {
  var CheckBox, ForeignKey, InputWidget, SelectField, TextField, TextareaField, Widget, widgetCount,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  widgetCount = 0;

  Widget = (function() {
    Widget.prototype.tag = 'div';

    function Widget() {
      this.classes = [];
    }

    Widget.prototype.ngModel = function(attrs) {
      return 'record.' + attrs.name;
    };

    Widget.prototype.getId = function(id) {
      return 'katrid-input-' + id.toString();
    };

    Widget.prototype.getWidgetAttrs = function(scope, el, attrs, field) {
      var classes, cls, html, i, len, ref;
      html = '';
      if (field.required) {
        html = ' required';
      }
      html += ' ng-model="' + this.ngModel(attrs) + '"';
      classes = '';
      ref = this.classes;
      for (i = 0, len = ref.length; i < len; i++) {
        cls = ref[i];
        classes += ' ' + cls;
      }
      if (classes) {
        html += ' class="' + classes + '"';
      }
      return html;
    };

    Widget.prototype.template = function(scope, el, attrs, field, type) {
      var html, id;
      if (type == null) {
        type = 'text';
      }
      widgetCount++;
      id = this.getId(widgetCount);
      html = '<' + this.tag + ' id="' + id + '" type="' + type + '" name="' + attrs.name + '" ' + this.getWidgetAttrs(scope, el, attrs, field) + '>';
      attrs._id = id;
      return html;
    };

    Widget.prototype.link = function(scope, el, attrs, $compile, field) {};

    return Widget;

  })();

  InputWidget = (function(superClass) {
    extend(InputWidget, superClass);

    InputWidget.prototype.tag = 'input';

    function InputWidget() {
      InputWidget.__super__.constructor.apply(this, arguments);
      this.classes.push('form-control');
    }

    return InputWidget;

  })(Widget);

  TextField = (function(superClass) {
    extend(TextField, superClass);

    function TextField() {
      return TextField.__super__.constructor.apply(this, arguments);
    }

    TextField.prototype.getWidgetAttrs = function(scope, el, attrs, field) {
      var html;
      html = TextField.__super__.getWidgetAttrs.call(this, scope, el, attrs, field);
      if (field.max_length) {
        html += ' maxlength="' + field.max_length.toString() + '"';
      }
      return html;
    };

    TextField.prototype.template = function(scope, el, attrs, field) {
      var html;
      html = TextField.__super__.template.call(this, scope, el, attrs, field);
      html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>';
      return html;
    };

    return TextField;

  })(InputWidget);

  SelectField = (function(superClass) {
    extend(SelectField, superClass);

    function SelectField() {
      return SelectField.__super__.constructor.apply(this, arguments);
    }

    SelectField.prototype.tag = 'select';

    SelectField.prototype.template = function(scope, el, attrs, field) {
      var html, id;
      widgetCount++;
      id = this.getId(widgetCount);
      console.log('scope', scope);
      html = '<' + this.tag + ' id="' + id + '" name="' + attrs.name + '" ' + this.getWidgetAttrs(scope, el, attrs, field) + '>' + '<option ng-repeat="choice in view.fields.' + attrs.name + '.choices" value="${choice[0]}">${choice[1]}</option>' + '>';
      attrs._id = id;
      html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>';
      return html;
    };

    return SelectField;

  })(InputWidget);

  ForeignKey = (function(superClass) {
    extend(ForeignKey, superClass);

    function ForeignKey() {
      return ForeignKey.__super__.constructor.apply(this, arguments);
    }

    ForeignKey.prototype.tag = 'input foreignkey';

    ForeignKey.prototype.template = function(scope, el, attrs, field) {
      var html;
      html = ForeignKey.__super__.template.call(this, scope, el, attrs, field, 'hidden');
      html = '<div><label for="' + attrs._id + '">' + field.caption + '</label>' + html + '</div>';
      return html;
    };

    return ForeignKey;

  })(Widget);

  TextareaField = (function(superClass) {
    extend(TextareaField, superClass);

    function TextareaField() {
      return TextareaField.__super__.constructor.apply(this, arguments);
    }

    TextareaField.prototype.tag = 'textarea';

    return TextareaField;

  })(TextField);

  CheckBox = (function(superClass) {
    extend(CheckBox, superClass);

    function CheckBox() {
      CheckBox.__super__.constructor.apply(this, arguments);
      this.classes = [];
    }

    CheckBox.prototype.getWidgetAttrs = function(scope, el, attrs, field) {
      var classes, cls, html, i, len, ref;
      html = '';
      html += ' ng-model="' + this.ngModel(attrs) + '"';
      classes = '';
      ref = this.classes;
      for (i = 0, len = ref.length; i < len; i++) {
        cls = ref[i];
        classes += ' ' + cls;
      }
      if (classes) {
        html += ' class="' + classes + '"';
      }
      return html;
    };

    CheckBox.prototype.template = function(scope, el, attrs, field) {
      var html, s;
      html = CheckBox.__super__.template.call(this, scope, el, attrs, field, 'checkbox');
      s = '<div>';
      if (field.help_text) {
        s += '<label for="' + attrs._id + '">' + field.caption + '</label>';
      }
      html = s + '<div class="checkbox"><label>' + html;
      if (field.help_text) {
        html += field.help_text;
      } else {
        html += field.caption;
      }
      html += '</label></div></div>';
      return html;
    };

    return CheckBox;

  })(InputWidget);

  Katrid.uiKatrid.directive('foreignkey', function() {
    return {
      restrict: 'A',
      require: 'ngModel',
      link: function(scope, el, attrs, controller) {
        var config, f, newItem, sel;
        f = scope.view.fields['model'];
        sel = el;
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
              msg = Katrid.i18n.gettext('Create <i>"{0}"</i>...');
              r = (function() {
                var i, len, ref, results;
                ref = data.result;
                results = [];
                for (i = 0, len = ref.length; i < len; i++) {
                  item = ref[i];
                  results.push({
                    id: item[0],
                    text: item[1]
                  });
                }
                return results;
              })();
              if (sel.data('select2').search.val()) {
                r.push({
                  id: newItem,
                  text: msg
                });
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
            var v;
            v = controller.$modelValue;
            if (v) {
              return cb({
                id: v[0],
                text: v[1]
              });
            }
          }
        };
        sel = sel.select2(config);
        sel.on('change', function(e) {
          var service, v;
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
          if (controller.$viewValue) {
            return sel.select2('val', controller.$viewValue[0]);
          } else {
            return sel.select2('val', null);
          }
        };
      }
    };
  });

  this.Katrid.UI.Widgets = {
    Widget: Widget,
    InputWidget: InputWidget,
    TextField: TextField,
    SelectField: SelectField,
    ForeignKey: ForeignKey,
    TextareaField: TextareaField,
    CheckBox: CheckBox
  };

}).call(this);

//# sourceMappingURL=widgets.js.map

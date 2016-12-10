$.datepicker.setDefaults($.datepicker.regional[document.documentElement.lang]);

var getval = function (val) {
  if ((typeof(val) === 'object') && val && val.id) return val.id;
  else if ((val == null) || (val == '')) return null;
  else return val;
};

var extraMods = [];

if (window.ngKeopsExtraModules) extraMods = window.ngKeopsExtraModules;

var keopsApp = angular.module('keopsApp', ['ngRoute', 'ngCookies', 'ngSanitize', 'ui.validate', 'ui.erp', 'ui.bootstrap', 'ui.mask'].concat(extraMods), function ($routeProvider, $locationProvider, $httpProvider) {
  $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded';
}).config(['$routeProvider', '$locationProvider',
  function ($routeProvider, $locationProvider) {
    $routeProvider
        .when('/content/show/:app/:content/', {
          templateUrl: function (params) {
            var u = '/client/content/show/' + params.app + '/' + params.content + '/';
            if (params.mode)
              u += '?' + $.param({mode: params.mode});
            return u;
          }
        })
        .when('/', {
          templateUrl: '/client/home/dashboard/'
        })
  }
]).run(['$http', '$cookies', function ($http, $cookies) {
  $http.defaults.headers.post['X-CSRFToken'] = $cookies.csrftoken;
}]);

// SharedData factory
keopsApp.factory('SharedData', function ($rootScope, $sce, $timeout) {
  var sharedData = {alerts: []};

  sharedData.addAlert = function (type, msg) {
    msg = $sce.trustAsHtml(msg);
    console.log(msg);
    if (type == 'error') type = 'danger';
    sharedData.alerts.push({
      type: type, msg: msg, timer: $timeout(function () {
        sharedData.alerts.splice(0, 1);
      }, 10000)
    });
  };

  sharedData.closeAlert = function (index) {
    var alert = sharedData.alerts[index];
    $timeout.cancel(alert.timer);
    $rootScope.alerts.splice(index, 1);
  };

  return sharedData;
});


// List factory/controller
keopsApp.factory('List', function ($http, SharedData, $location) {
  var List = function () {
    this.items = [];
    this.loading = false;
    this.start = 0;
    this.total = null;
    this.loaded = false;
    this.index = 0;
    this.selection = 0;
    this.selItems = [];
    SharedData.list = this;
  };

  List.prototype.nextPage = function (query) {
    if (this.loading || this.loaded) return;
    this.loading = true;
    var params = {
      p: this.start,
      l: 25
    };

    if (query) params['q'] = query;

    var url = "/api/content/" + this.model.replace('.', '/') + '/';
    if (this.total === null) {
      params['t'] = 1;
      params['p'] = 1;
    }
    $http({
      url: url,
      method: 'GET',
      params: params
    }).success(function (data) {
      this.total = data.total;
      rows = data.items;
      for (var i = 0; i < rows.length; i++)
        this.items.push(rows[i].data);
      this.start = this.items.length;
      this.loading = false;
      this.loaded = this.items.length == this.total;
    }.bind(this));
  };

  List.prototype.query = function (query) {
    this.q = query;
    this.total = null;
    this.start = 0;
    this.loaded = false;
    this.items = [];
    this.nextPage(query);
  };

  List.prototype.deleteSelection = function () {
    if (confirm("Confirma a exclusão do(s) registro(s) selecionado(s)?")) {
      var delItems = [];
      var selItems = this.selItems;
      var items = this.items;
      var self = this;
      for (var i = 0; i < this.selItems.length; i++) {
        var row = this.selItems[i];
        delItems.push(row.id);
      }
      var params = {model: this.model, id: delItems};
      $http({
        url: '/api/content/' + this.model.replace('.', '/') + '/',
        method: 'DELETE',
        params: params
      }).success(function (data) {
        if (data.success) {
          SharedData.addAlert("success", data.message);
          for (var i=0;i<selItems.length;i++) {
            items.splice(items.indexOf(selItems[i]), 1);
          }
          selItems.length = 0;
          self.selection = 0;
        }
      });
    }
  };

  List.prototype.init = function (model, q) {
    this.model = model;
    this.query(q);
  };

  List.prototype.itemClick = function (item, search, index) {
    if (item.id) $location.search({mode: 'form', id: item.id});
  };

  return List;
});


keopsApp.controller('AppController', function ($scope, $rootScope, $location, SharedData, $http) {
  $scope.alerts = SharedData.alerts;

  $scope.authenticate = function (user, password) {
    $http({
      method: 'POST',
      url: '/api/auth/login/',
      headers: {'Content-Type': 'application/json'},
      data: { user: user, password: password }
    }).success(function (data) {
      if (!angular.isDefined($scope.alerts)) $scope.alerts = [];
      else $scope.alerts.splice(0, $scope.alerts.length);
      if (data.success) {
        $scope.alerts.push({ type: 'success', message: katrid.gettext('Please wait, redirecting page...')});
        window.location.href = '/';
      }
      else $scope.alerts.push({ type: 'danger', 'message': data.message });
    });
  }
});


keopsApp.controller('ListController', function ($scope, $location, List) {
  $scope.list = new List();

  $scope.itemClick = function (url, search, index) {
    window.location.href = $scope.controllerUrl + url;
  };

  $scope.toggleCheckAll = function () {
    var c = $('#action-toggle')[0].checked;
    $('.action-select').each(function () {
      $(this).checked = true;
      $(this).prop('checked', c);
    });
    $scope.list.selection = $('.action-select:checked').length;
    if (c)
      $scope.list.selItems = $scope.list.items;
    else
      $scope.list.selItems = [];
  };

  $scope.selectItem = function (item) {
    if (item) {
      var idx = $scope.list.selItems.indexOf(item);
      if (idx === -1)
        $scope.list.selItems.push(item);
      else
        $scope.list.selItems.splice(idx, 1);
    }
    $('#action-toggle').prop('checked', $('.action-select:not(:checked)').length === 0);
    $scope.list.selection = $('.action-select:checked').length;
  };

  $scope.goto = function (url, target) {
    window.location.href = url;
  };

  $scope.newItem = function () {
    var params = $location.search();
    params['mode'] = 'form';
    params['state'] = 'new';
    $location.search(params);
  };

  $scope.showForm = function (id) {
    var params = $location.search();
    params['mode'] = 'form';
    params['id'] = id;
    $location.search(params);
  }

});


// Form factory/controller
keopsApp.factory('Form', function ($http, SharedData, $location, $routeParams) {
  var Form = function () {
    this.data = {};
    this.item = {};
    this.subItems = {};
    this.children = [];
    this.deleted = [];
    this.loading = false;
    this.start = -1;
    this.total = null;
    this.loaded = false;
    this.write = false;
    this.model = null;
    this.element = null;
    this.readonly = null;
    this.state = null;
    this.pk = $location.search().id;
    this.url = "/api/content/";
    if (SharedData.list) {
      this.start = SharedData.list.index - 1;
      this.total = SharedData.list.total;
    }
  };

  Form.prototype.addChild = function (obj) {
    this.children.push(obj);
  };

  Form.prototype.addSubItem = function (obj) {
    var cf = obj.name;
    if (!this.subItems[cf]) this.subItems[cf] = [];
    var s = this.subItems[cf];
    if (s.indexOf(obj) === -1) s.push(obj);
  };

  Form.prototype.removeSubItem = function (obj) {
    var cf = obj.name;
    if (!this.subItems[cf]) this.subItems[cf] = [];
    var s = this.subItems[cf];
    if (s && (s.indexOf(obj))) s.splice(s.indexOf(obj), 1);
  };


  Form.prototype.newItem = function (pk) {
    var params = {model: this.model};
    var url = '/db/read';
    if (pk) {
      params['action'] = 'duplicate_selected';
      params['pk'] = pk;
    }
    $http({
      method: 'POST',
      url: url,
      params: params
    }).success(function (data) {
      this.write = true;
      this.item = data;
      this.item.__str__ = katrid.gettext('<New>')
    }.bind(this));
  };

  Form.prototype.loadFormset = function (field) {
    if (this.pk) {
      var fname = field.split('.');
      var m, f;
      if (fname.length === 1) {
        m = this.model + '.' + fname[0];
      } else {
        m = fname[0] + '.' + fname[1];
        f = fname[2];
      }

      var vData = [];
      this.subitems[field.replace(/\./g, '_')] = vData;

      var params = {model: m, field: f, pk: this.pk};
      var url = '/db/read/';
      /*$http({
       method: 'GET',
       url: url,
       params: params
       }).success(function (data) {
       for (var i in data.items) {
       var d = data.items[i].data;
       d.__model__ = m;
       vData.push(d);
       }
       }.bind(this));*/
    }
  };

  Form.prototype.nextPage = function () {
    if (this.loading || this.loaded) return;
    this.loading = true;
    var model = this.model;

    var url = this.url + model.replace('.', '/') + '/';
    var params = {mode: 'form'};
    if (this.state === 'new') params.state = 'new';
    else if (this.pk) params.id = this.pk;
    $http({
      method: 'GET',
      url: url,
      params: params
    }).success(function (data) {
      this.data = data.items[0].data;
      if (this.state === 'new') {
        var d = data.items[0].data;
        for (var i in d) if (this.scope.dataForm[i]) this.scope.dataForm[i].$setDirty();
      }
      var id = data.items[0].id;
      if (!this.pk) $location.search('id', id);
      this.pk = id;
      this.loading = false;
      this.loaded = this.start == this.total - 1;
      //this.masterChangeNotification();
      delete SharedData.list;
    }.bind(this));
  };

  Form.prototype.prevPage = function () {
    if (this.start === 0) return;
    this.loading = true;
    this.loaded = false;
    var model = this.model;

    this.start--;
    var url = this.url + 'p=' + this.start;
    $http.get(url).success(function (data) {
      if (this.total === null) this.total = data.total;
      this.item = data.items[0];
      $location.search('pk', this.item.pk);
      this.loading = false;
      //this.masterChange();
    }.bind(this));
  };

  Form.prototype.masterChangeNotification = function () {
    // notify nested form remote items
    var formItem = this.item;
    formItem.subItems = {};
    var items = this.element.find('[remote]');
    var remoteitems = [];
    for (var i = 0; i < items.length; i++) remoteitems.push(angular.element(items[i]).attr('name'));
    // make params
    var data = {model: this.model, pk: this.item.pk, items: angular.toJson(remoteitems)};
    // load remote data
    $http({
      method: 'GET',
      url: '/db/read/items',
      params: data
    }).
    success(function (data) {
      for (var i = 0; i < items.length; i++) {
        var item = angular.element(items[i]);
        var name = item.attr('name');
        if (data[name].items) formItem[name] = data[name].items;
        else formItem[name] = data[name];
      }
    });
  };

  Form.prototype.cancel = function () {
    this.write = false;
    this.refresh();
  };

  Form.prototype.refresh = function () {
    var pk = $location.search()['pk'];
    if (pk)
      $http({
        method: 'GET',
        url: '/db/read',
        params: {limit: 1, model: this.model, pk: $location.search()['pk']}
      }).success(function (data) {
        jQuery.extend(this.item, data.items[0]);
        this.masterChange();
      }.bind(this));
  };

  Form.prototype.getGridFields = function () {
    var items = this.element.find('[grid-field]');
    var r = {};
    // check item changes
    for (var i = 0; i < items.length; i++) {
      var item = angular.element(items[i]);
      var name = item.attr('name');
      r[name] = this.item[name];
    }
    ;
    return r;
  };

  Form.prototype.getNestedForm = function (data) {
    var r = {};
    var b = false;
    if (data.$name)
      for (var i in data) {
        if (i[0] !== '$') {
          var v = data[i];
          if (v.$modelValue !== undefined) {
            r[i] = v.$modelValue;
            b = true;
          }
        }
      }
    if (b) {
      var fname = data.$name.split('.');
      var model = fname[0] + '.' + fname[1];
      var field = fname[2];
      r['__model__'] = model;
      r['__key__'] = field;
      r[field] = null;
      return r;
    }
  };

  Form.prototype.deleteItem = function (data, index) {
    if (confirm("Confirma a exclusão do item?")) {
      item = data[index];
      if (item.pk)
        this.deleted.push(item);
      data.splice(index, 1);
    }
  };

  Form.prototype.init = function (model) {
    this.model = model;
    var src = $location.search();
    if ($routeParams["id"]) this.pk = $routeParams["id"];
    else this.pk = $location.search()["id"];
    if (src.state === 'new') this.state = 'new';
    this.nextPage();
  };

  return Form;
});

keopsApp.controller('FormController', function ($scope, $http, Form, $location, $element, $modal, $timeout, $sce, SharedData) {
  $scope.form = new Form();
  $scope._counters = {};
  $scope.form.scope = $scope;
  $scope.form.element = $element;

  $scope.search = function (url, search) {
    $location.path(url).search(search);
  };

  $scope.lookupData = function (url, model, query) {
    var promise = $http({
      method: 'GET',
      url: url,
      params: {query: query, model: model}
    })
        .then(function (response) {
          return response.data;
        });
    promise.$$v = promise;
    return promise;
  };

  $scope.openResource = function (url, search) {
    $location.path(url).search(search).replace();
  };

  $scope.fieldChangeNotification = function (field) {
    var data = this.collectData(false, false);
    $http({
      method: 'POST',
      url: '/api/change/' + $scope.form.model.replace('.', '/') + '/',
      params: {field: field},
      headers: {'Content-Type': 'application/json'},
      data: data
    }).
    success(function (data) {
      //jQuery.extend($scope.form.item, data.values);
    });
  };

  $scope.showDetail = function (model, detail, item) {
    var field = $scope.form.item[detail];
    var options = {
      controller: 'DialogController',
      resolve: {
        data: function () {
          form = {item: {}}
          if (item) {
            jQuery.extend(form.item, item);
            form.ref = item;
          }
          form.field = field;
          form.instance = $scope.form;
          return form;
        }
      },
      templateUrl: '/admin/detail/?model=' + model + '&field=' + detail
    };
    var dialog = $modal.open(options);

    dialog.result.then(function (form) {
      form.instance.nestedDirty = true;
      if (form.ref) {
        if (!form.item.__state__) form.item.__state__ = 'modified';
        jQuery.extend(form.ref, form.item);
      }
      else {
        form.item.__state__ = 'created';
        form.field.push(form.item);
      }
    }, function () {
    });
  };

  $scope.confirmDelete = function (message) {
    var options = {
      controller: 'DialogController',
      resolve: {
        data: function () {
          return $scope.form;
        }
      },
      templateUrl: '/static/katrid/html/confirm_delete.html'
    };
    var dialog = $modal.open(options);

    dialog.result.then(function (form) {
      $http({
        method: 'POST',
        url: '/admin/action/?action=delete_selected',
        params: {pk: form.item.pk, model: form.model}
      }).success(function (data) {
        for (var i in data) {
          var i = data[i];
          SharedData.addAlert(i.alert, i.message);
        }
        if (data[data.length - 1].success) $scope.form.nextPage();
      }).error(function (data) {
        window.open('error').document.write(data);
      });
    }, function () {
    });
  };

  $scope.sum = function (item, attr) {
    var r = 0;
    if (item)
      for (var i=0;i<item.length;i++) {
        var obj = item[i];
        r += obj[attr] || 0;
      }
    return r;
  };

  $scope.tableRowFilter = function (obj) {
    return obj.__state__ !== 'deleted';
  };

  $scope.collectData = function (dirtyOnly, validOnly) {
    var form = this.dataForm;
    if (validOnly && !form.$valid) return;
    var data = {};

    // formset items

    var getSubItemObj = function (self, nm) {
      var subitem = self.form.data[nm];
      var r = [];
      if (subitem.length)
        for (var i = 0; i < subitem.length; i++) {
          var s = subitem[i];
          var obj = {};
          var modified = false;
          var frm = form[nm + '-' + i.toString()];
          if (frm) {
            for (var x in s) if (x[0] !== '$') {
              var f = frm[x];
              //if (f && f.$dirty) obj[x] = f.$modelValue;
              modified = true;
              // TODO apply modified fields only
              if (f) obj[x] = getval(f.$modelValue);
            }
            if (frm.id) obj.id = frm.id.$modelValue;
          }
          if (modified) r.push(obj);
        }
      if (r.length) return r;
    };

    // save data

    for (var i in this.form.data) {
      var field = form[i];
      if (field && (!dirtyOnly || field.$dirty)) data[i] = getval(field.$modelValue);
      // check children (formsets)
      else if (this.form.children.indexOf(i) > -1) {
        s = getSubItemObj(this, i);
        if (s) data[i] = s;
      }
    }

    // grid items

    var subItems = this.form.subItems;

    var collect = function (obj) {
      if (obj.op === 'delete') return obj;
      var r = {};
      for (var i in obj) {
        if (obj.hasOwnProperty(i)) {
          if (i[0] !== '_') r[i] = obj[i];
        }
      }
      if (obj._modifiedFields.length) {
        var data = {};
        for (var i in obj._modifiedFields) {
          var s = obj._modifiedFields[i];
          data[s] = getval(obj.data[s]);
        }
        r.data = data;
        return r;
      }
    };

    for (i in subItems) {
      var rows = subItems[i];
      var items = [];
      for (var x=0;x<rows.length;x++) {
        var childObj = collect(rows[x]);
        if (childObj) items.push(childObj);
      }
      if (items.length) data[i] = items;
    }
    if (this.form.pk) data['id'] = this.form.pk;
    return [data];
  };

  $scope.submit = function () {
    $scope.dataForm.$setSubmitted();
    if (!$scope.dataForm.$valid) return false;
    var data = this.collectData(true, true);
    var postUrl = '/api/content/' + this.form.model.replace('.', '/') + '/';
    var params = {};
    console.log(data);
    return $http({
      method: 'POST',
      url: postUrl,
      data: data,
      headers: {'Content-Type': 'application/json'},
      params: params
    }).success(function (data) {
      if (data.success) $scope.showList();
    });
    /*        var i, item;
     var form = this.dataForm;
     if (form.$dirty) {
     var data = {};
     for (i in form) {
     item = form[i];
     if ((i[0] !== '$') && (i.indexOf('.') === -1) && item.$dirty) {
     data[i] = item.$modelValue;
     }
     }
     };
     if (data || this.form.deleted.length) {

     //var nested = $element.find('[ng-form]');
     // check item changes
     data = { data: data, nested: [] }
     for (i in this.form.deleted) {
     data.nested.push({ pk: this.form.deleted[i].pk, __action__: 'delete', __model__: this.form.deleted[i].__model__ });
     }
     for (i in form) {
     item = form[i];
     if (item && item.$$parentForm && item.$dirty) {
     data.nested.push(this.form.getNestedForm(item));
     }
     }

     var postUrl = '/api/content/' + this.form.model.replace('.', '/') + '/';
     var params = {};
     if ($scope.form.data && this.form.data.pk) params['id'] = this.form.data.pk;
     return $http(
     {
     url: postUrl,
     data: data,
     params: params
     }
     ).success(function (data, status, headers, config) {
     if (data.success) {
     console.log(data.message);
     SharedData.addAlert('success', data['message']);
     if ($scope.backUrl) window.location.href = $scope.backUrl;
     else {
     var params = $location.search();
     params['mode'] = 'list';
     $location.search(params);
     }
     }

     }.bind(this)).
     error(function (data) {
     window.open('error').document.write(data);
     });
     }
     else {
     SharedData.addAlert('warning', 'Não existem dados penendetes de gravação!');
     var search = $location.search();
     search['mode'] = 'list';
     $location.search(search);
     }*/
  };

  $scope.adminAction = function (action, data) {
    $scope.alerts.length = 0;
    var params = {model: this.model};
    var url = '/admin/action/';
    var pk = this.form.pk;
    params['action'] = action;
    params['pk'] = this.form.pk;
    params['model'] = this.form.model;
    params['data'] = data;
    $http.post(url, params).success(function (data) {
      $scope._evalData(data);
    });
  };

  $scope._evalData = function (data) {
    for (var i in data) {
      i = data[i];
      var s = i.message;
      if (i.success && (typeof i.message === 'object')) {
        $scope.form.nestedDirty = false;
        form.$setPristine();
        $scope.form.write = false;
        jQuery.extend($scope.form.item, data.data);
      }
      else if (!i.success) {
        $scope.addAlert(i.alert, s);
      }
      else $scope.addAlert(i.alert, s);
    }
  };

  $scope.showList = function () {
    var params = $location.search();
    params['mode'] = 'list';
    params['id'] = null;
    $location.search(params);
  }

});

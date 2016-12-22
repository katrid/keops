// Generated by CoffeeScript 1.10.0
(function() {
  var DataSource, Record;

  DataSource = (function() {
    function DataSource(scope) {
      this.scope = scope;
    }

    DataSource.prototype.findById = function(id) {
      var i, len, rec, ref;
      ref = this.scope.records;
      for (i = 0, len = ref.length; i < len; i++) {
        rec = ref[i];
        if (rec.id === id) {
          return rec;
        }
      }
    };

    DataSource.prototype.hasKey = function(id) {
      var i, len, rec, ref, results;
      ref = this.scope.records;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        rec = ref[i];
        if (rec.id === id) {
          results.push(true);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    DataSource.prototype.getIndex = function(obj) {
      var rec;
      rec = this.findById(obj.id);
      return this.scope.records.indexOf(rec);
    };

    DataSource.prototype.search = function(params) {
      var me;
      me = this;
      return this.scope.model.search(params, {
        count: 1
      }).done(function(res) {
        return me.scope.$apply(function() {
          if (res.result.count != null) {
            me.scope.recordCount = res.result.count;
          }
          return me.scope.records = res.result.data;
        });
      });
    };

    DataSource.prototype.goto = function(index) {
      return this.scope.moveBy(index - this.scope.recordIndex);
    };

    DataSource.prototype.moveBy = function(index) {
      var newIndex;
      newIndex = this.scope.recordIndex + index - 1;
      if (newIndex > -1 && newIndex < this.scope.records.length) {
        this.scope.recordIndex = newIndex + 1;
        return $location.search('id', this.scope.records[newIndex].id);
      }
    };

    DataSource.prototype.get = function(id) {
      var me;
      me = this;
      return this.scope.model.get(id).done(function(res) {
        return me.scope.$apply(function() {
          me.scope.record = res.result.data[0];
          return me.scope.recordId = me.scope.record.id;
        });
      });
    };

    DataSource.prototype.next = function() {
      return this.scope.moveBy(1);
    };

    DataSource.prototype.prior = function() {
      return this.scope.moveBy(-1);
    };

    DataSource.prototype.setRecordIndex = function(index) {
      return this.scope.recordIndex = index + 1;
    };

    return DataSource;

  })();

  Record = (function() {
    function Record(res1) {
      this.res = res1;
      this.data = this.res.data;
    }

    return Record;

  })();

  Katrid.Data = {
    DataSource: DataSource,
    Record: Record
  };

}).call(this);

//# sourceMappingURL=data.js.map

(function() {
  this.objectCollection = function(array) {
    if (!array.indexOf) {
      array.indexOf = function(needle) {
        var index, item, _len, _results;
        _results = [];
        for (index = 0, _len = array.length; index < _len; index++) {
          item = array[index];
          _results.push(item === needle ? index : void 0);
        }
        return _results;
      };
      -1;
    }
    array.findBy = function(prop, value) {
      var index, item, _len;
      for (index = 0, _len = array.length; index < _len; index++) {
        item = array[index];
        if (item[prop] === value) {
          return item;
        }
      }
      return false;
    };
    array.eraseBy = function(prop, value) {
      var item;
      item = array.findBy(prop, value);
      return array.erase(item);
    };
    array.insert = function(item, index) {
      if (index == null) {
        index = 0;
      }
      return array.splice(index, 0, item);
    };
    array.erase = function(victim) {
      var index, prospect, _len, _results;
      _results = [];
      for (index = 0, _len = array.length; index < _len; index++) {
        prospect = array[index];
        _results.push(prospect === victim ? array.splice(index, 1) : void 0);
      }
      return _results;
    };
    array.sortBy = (function() {
      var sorters;
      sorters = {
        string: function(a, b) {
          if (a < b) {
            return -1;
          } else if (a > b) {
            return 1;
          } else {
            return 0;
          }
        },
        number: function(a, b) {
          return a - b;
        }
      };
      return function(prop) {
        var type;
        type = typeof array[0][prop] || 'string';
        return array.sort(function(a, b) {
          return sorters[type](a[prop], b[prop]);
        });
      };
    })();
    return array;
  };
}).call(this);

(function() {
  define('compiled/util/invoker', function() {
    return function(obj) {
      obj.invoke = function(method) {
        var args;
        args = [].splice.call(arguments, 0, 1);
        return (this[method] || this.noMethod).apply(this, arguments);
      };
      if (!obj.noMethod) {
        obj.noMethod = function() {};
      }
      return obj;
    };
  });
}).call(this);

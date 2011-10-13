(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define(['compiled/util/invoker'], function(invoker) {
    var obj;
    obj = invoker({
      one: function() {
        return 1;
      },
      noMethod: function() {
        return 'noMethod';
      }
    });
    module('Invoker');
    test('should call a method with invoke', __bind(function() {
      var result;
      result = obj.invoke('one');
      return equal(result, 1);
    }, this));
    return test("should call noMethod when invoked method doesn't exist", __bind(function() {
      var result;
      result = obj.invoke('non-existent');
      return equal(result, 'noMethod');
    }, this));
  });
}).call(this);

define(function(require) {
  var Subject = require('core/environment');

  describe('Core::Environment', function() {
    describe('#parseQueryString', function() {
      it('should work', function() {
        var query = Subject.parseQueryString('foo=bar');

        expect(query.foo).toEqual('bar');
      });

      it('should extract array items', function() {
        var query = Subject.parseQueryString('foo=bar&arr[]=1&arr[]=2');

        expect(query.foo).toEqual('bar');
        expect(query.arr).toEqual(['1','2']);
      })
    });
  });
});
define(function(require) {
  var arrayWrap = require('util/array_wrap');

  describe('Util::arrayWrap', function() {
    it('should work', function() {
      expect(arrayWrap('foo')).toEqual([ 'foo' ]);
    });
  });
});
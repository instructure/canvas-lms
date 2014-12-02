define(function(require) {
  var Subject = require('models/event');

  describe('Models.Event', function() {
    describe('constructor', function() {
      it('should work', function() {
        expect(function() {
          new Subject();
        }).not.toThrow();
      });
    });
  });
});
define(function(require) {
  var Subject = require('models/event');
  var EventFixture = require('json!fixtures/event');

  describe('Models.Event', function() {
    describe('constructor', function() {
      it('should work', function() {
        expect(function() {
          new Subject();
        }).not.toThrow();
      });
    });

    it('fixture should work', function() {
      expect(EventFixture.name).toEqual('event');
    })
  });
});
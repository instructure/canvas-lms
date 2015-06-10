define(function(require) {
  var Subject = require('core/controller');
  var config = require('config');

  describe('Controller', function() {
    describe('#start', function() {
      this.promiseSuite = true;

      it('should work', function() {
        expect(function() {
          Subject.start(jasmine.createSpy());
        }).not.toThrow();
      });
    });

    describe('#load', function() {
      it('should work', function() {
        expect(function() {
          Subject.load();
        }).not.toThrow();
      });
    });
  });
});
define((require) => {
  const Subject = require('core/controller');
  const config = require('config');

  describe('Controller', () => {
    describe('#start', function () {
      this.promiseSuite = true;

      it('should work', () => {
        expect(() => {
          Subject.start(jasmine.createSpy());
        }).not.toThrow();
      });
    });

    describe('#load', () => {
      it('should work', () => {
        expect(() => {
          Subject.load();
        }).not.toThrow();
      });
    });
  });
});

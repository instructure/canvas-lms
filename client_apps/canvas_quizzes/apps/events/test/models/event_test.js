define((require) => {
  const Subject = require('models/event');

  describe('Models.Event', () => {
    describe('constructor', () => {
      it('should work', () => {
        expect(() => {
          new Subject();
        }).not.toThrow();
      });
    });
  });
});

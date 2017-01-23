define((require) => {
  const arrayWrap = require('util/array_wrap');

  describe('Util::arrayWrap', () => {
    it('should work', () => {
      expect(arrayWrap('foo')).toEqual(['foo']);
    });
  });
});

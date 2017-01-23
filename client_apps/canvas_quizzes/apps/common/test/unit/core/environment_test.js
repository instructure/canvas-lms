define((require) => {
  const Subject = require('core/environment');

  describe('Core::Environment', () => {
    describe('#parseQueryString', () => {
      it('should work', () => {
        const query = Subject.parseQueryString('foo=bar');

        expect(query.foo).toEqual('bar');
      });

      it('should extract array items', () => {
        const query = Subject.parseQueryString('foo=bar&arr[]=1&arr[]=2');

        expect(query.foo).toEqual('bar');
        expect(query.arr).toEqual(['1', '2']);
      })
    });
  });
});

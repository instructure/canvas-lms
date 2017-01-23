define((require) => {
  const Inflections = require('util/inflections');

  describe('Inflections', () => {
    describe('#camelize', () => {
      const subject = Inflections.camelize;

      it('foo to Foo', () => {
        expect(subject('foo')).toEqual('Foo');
      });

      it('foo_bar to FooBar (default)', () => {
        expect(subject('foo_bar')).toEqual('FooBar');
      });

      it('foo_bar to fooBar', () => {
        expect(subject('foo_bar', true)).toEqual('fooBar');
      });

      it('fooBar to fooBar', () => {
        expect(subject('fooBar', true)).toEqual('fooBar');
      });

      it('does not blow up with nulls or empty strings', () => {
        expect(() => {
          subject(undefined);
        }).not.toThrow();

        expect(() => {
          subject('');
        }).not.toThrow();
      });
    });
  });
});

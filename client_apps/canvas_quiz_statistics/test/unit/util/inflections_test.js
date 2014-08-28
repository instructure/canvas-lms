define(function(require) {
  var Inflections = require('util/inflections');

  describe('Inflections', function() {
    describe('#camelize', function() {
      var subject = Inflections.camelize;

      it('foo to Foo', function() {
        expect(subject('foo')).toEqual('Foo');
      });

      it('foo_bar to FooBar (default)', function() {
        expect(subject('foo_bar')).toEqual('FooBar');
      });

      it('foo_bar to fooBar', function() {
        expect(subject('foo_bar', true)).toEqual('fooBar');
      });

      it('fooBar to fooBar', function() {
        expect(subject('fooBar', true)).toEqual('fooBar');
      });

      it('does not blow up with nulls or empty strings', function() {
        expect(function() {
          subject(undefined);
        }).not.toThrow();

        expect(function() {
          subject('');
        }).not.toThrow();
      });
    });
  });
});
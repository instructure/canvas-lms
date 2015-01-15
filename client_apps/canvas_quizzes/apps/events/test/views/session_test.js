define(function(require) {
  var Subject = require('jsx!views/session');

  describe('Views::Session', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
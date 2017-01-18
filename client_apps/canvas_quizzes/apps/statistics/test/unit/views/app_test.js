define(function(require) {
  var Subject = require('jsx!views/app');
  var Statistics = require('stores/statistics');
  var _ = require('lodash');

  describe('Views.App', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
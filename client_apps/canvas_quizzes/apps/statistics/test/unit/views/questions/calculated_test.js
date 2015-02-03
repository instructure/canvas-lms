define(function(require) {
  var Subject = require('jsx!views/questions/calculated');

  describe('Views.Questions.Calculated', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
define(function(require) {
  var Subject = require('jsx!views/questions/short_answer');

  describe('Views.Questions.ShortAnswer', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
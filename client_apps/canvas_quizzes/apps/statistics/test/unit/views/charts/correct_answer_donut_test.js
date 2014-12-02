define(function(require) {
  var Subject = require('jsx!views/charts/correct_answer_donut');

  describe('Views.Charts.CorrectAnswerDonut', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

  });
});
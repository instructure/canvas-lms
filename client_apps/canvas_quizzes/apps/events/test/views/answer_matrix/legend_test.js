define(function(require) {
  var Subject = require('jsx!views/answer_matrix/legend');

  describe('Views::AnswerMatrix::Legend', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
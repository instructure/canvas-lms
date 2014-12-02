define(function(require) {
  var Subject = require('jsx!views/answer_matrix/table');

  describe('Views::AnswerMatrix::Table', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});
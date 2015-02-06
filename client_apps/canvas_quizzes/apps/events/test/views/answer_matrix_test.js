define(function(require) {
  var Subject = require('jsx!views/answer_matrix');

  describe('Views::AnswerMatrix', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    describe('inverted', function() {
      beforeEach(function() {
        setState({ invert: true });
      });

      it('should render', function() {
        expect(subject.isMounted()).toEqual(true);
      });
    });
  });
});
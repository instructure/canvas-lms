define(function(require) {
  var Subject = require('jsx!views/answer_matrix');

  describe('Views::AnswerMatrix', function() {
    reactRouterSuite(this, Subject, {
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    describe('inverted', function() {
      beforeEach(function() {
        subject.setState({ invert: true });
      });

      it('should render', function() {
        expect(subject.isMounted()).toEqual(true);
      });
    });
  });
});
define((require) => {
  const Subject = require('jsx!views/answer_matrix');

  describe('Views::AnswerMatrix', function () {
    reactRouterSuite(this, Subject, {
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });

    describe('inverted', () => {
      beforeEach(() => {
        subject.setState({ invert: true });
      });

      it('should render', () => {
        expect(subject.isMounted()).toEqual(true);
      });
    });
  });
});

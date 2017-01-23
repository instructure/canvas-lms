define((require) => {
  const Subject = require('jsx!views/question');

  describe('Views.Question', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

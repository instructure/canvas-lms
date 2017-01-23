define((require) => {
  const Subject = require('jsx!views/questions/short_answer');

  describe('Views.Questions.ShortAnswer', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

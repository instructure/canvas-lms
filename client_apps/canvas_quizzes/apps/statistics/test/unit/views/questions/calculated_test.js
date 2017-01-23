define((require) => {
  const Subject = require('jsx!views/questions/calculated');

  describe('Views.Questions.Calculated', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

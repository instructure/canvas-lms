define((require) => {
  const Subject = require('jsx!views/charts/correct_answer_donut');

  describe('Views.Charts.CorrectAnswerDonut', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

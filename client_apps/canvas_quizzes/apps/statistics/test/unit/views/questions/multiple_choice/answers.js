define(function(require) {
  var Subject = require('jsx!views/questions/multiple_choice/answers');
  var answerSetFixture = [
      { id: 'a1', text: 'red', responses: 4, correct: true, ratio: 100, user_names: ['One', 'Two', 'Three', 'Four']},
      { id: 'a2', text: 'green', responses: 0, ratio: 0 },
      { id: 'a3', text: 'blue', responess: 0, ratio: 0 }];

  describe('Views.Questions.MultipleChoice.Answers', function() {
    this.reactSuite({
      type: Subject
    });

    it('renders the correct CSS for correct answer', function() {
      setProps({
        answerSets: answerSetFixture,
      });
      expect('.answer-drilldown detail-section').toExist();
      expect(find('.correct').innerText).toMatch('red');

      click(find('.correct'));
      expect(find('.correct').innerText).toContain('Three');
    });
  });
});



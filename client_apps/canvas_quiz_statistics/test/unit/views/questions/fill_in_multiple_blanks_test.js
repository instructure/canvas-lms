define(function(require) {
  var Subject = require('jsx!views/questions/fill_in_multiple_blanks');
  var answerSetFixture = [
    {
      id: '1',
      text: 'color',
      answers: [
        { id: 'a1', text: 'red', responses: 4, correct: true, ratio: 100 },
        { id: 'a2', text: 'green', responses: 0, ratio: 0 },
        { id: 'a3', text: 'blue', responess: 0, ratio: 0 },
      ]
    },
    {
      id: '2',
      text: 'size',
      answers: [
        { id: 'b1', text: 'S', responses: 1, ratio: 0 },
        { id: 'b2', text: 'M', responses: 0, ratio: 0 },
        { id: 'b3', text: 'L', responses: 3, correct: true, ratio: 75 },
      ]
    }
  ];

  describe('Views.Questions.FillInMultipleBlanks', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('renders a tab for each answer set', function() {
      setProps({
        answerSets: [
          { id: '1', text: 'color' },
          { id: '2', text: 'size' }
        ],
      });

      expect('.answer-set-tabs button:contains("color")').toExist();
      expect('.answer-set-tabs button:contains("size")').toExist();
    });

    it('activates an answer set by clicking the tab', function() {
      setProps({
        answerSets: [
          { id: '1', text: 'color' },
          { id: '2', text: 'size' }
        ]
      });

      expect(find('.answer-set-tabs .active').innerText).toMatch('color');
      click('.answer-set-tabs button:contains("size")');
      expect(find('.answer-set-tabs .active').innerText).toMatch('size');
    });

    it('shows answer drilldown per answer set', function() {
      setProps({
        expanded: true,
        answerSets: answerSetFixture,
      });

      expect(find('.answer-set-tabs .active').innerText).toMatch('color');
      expect(find('.answer-drilldown').innerText).toContain('red');
      expect(find('.answer-drilldown').innerText).toContain('green');
      expect(find('.answer-drilldown').innerText).toContain('blue');

      click('.answer-set-tabs button:contains("size")');

      expect(find('.answer-set-tabs .active').innerText).toMatch('size');
      expect(find('.answer-drilldown').innerText).toContain('S');
      expect(find('.answer-drilldown').innerText).toContain('M');
      expect(find('.answer-drilldown').innerText).toContain('L');
    });

    it('updates the charts based on the active set', function() {
      setProps({
        participantCount: 4,
        answerSets: answerSetFixture,
      });

      expect(find('.correct-answer-ratio-section').innerText)
        .toMatch('100% of your students responded correctly.');
      expect(find('.answer-distribution-section .auxiliary').innerText)
        .toMatch('100%' + '4 students' + 'red');

      click('.answer-set-tabs button:contains("size")');

      expect(find('.correct-answer-ratio-section').innerText)
        .toMatch('75% of your students responded correctly.');
      expect(find('.answer-distribution-section .auxiliary').innerText)
        .toMatch('75%' + '3 students' + 'L');
    });
  });
});
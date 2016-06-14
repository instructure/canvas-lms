define(function(require) {
  var Subject = require('jsx!views/questions/fill_in_multiple_blanks');
  var answerSetFixture = [
    {
      id: '1',
      text: 'color',
      answers: [
        { id: 'a1', text: 'red', responses: 4, correct: true, ratio: 100, user_names: ['One', 'Two', 'Three', 'Four']},
        { id: 'a2', text: 'green', responses: 0, ratio: 0, user_names: []},
        { id: 'a3', text: 'blue', responess: 0, ratio: 0, user_names: []},
      ]
    },
    {
      id: '2',
      text: 'size',
      answers: [
        { id: 'b1', text: 'S', responses: 1, ratio: 0, user_names: [] },
        { id: 'b2', text: 'M', responses: 0, ratio: 0, user_names: [] },
        { id: 'b3', text: 'L', responses: 3, correct: true, ratio: 75, user_names: ['One', 'Two', 'Three'] },
      ]
    }
  ];

  describe('Views.Questions.FillInMultipleBlanks', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
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

    it('shows answer text per answer set', function() {
      setProps({
        answerSets: answerSetFixture,
      });

      debugger;
      expect(find('.answer-set-tabs .active').innerText).toMatch('color');
      var answerTextMatches = findAll("th.answer-textfield");
      expect(answerTextMatches[0].innerText).toEqual('red');
      expect(answerTextMatches[1].innerText).toEqual('green');
      expect(answerTextMatches[2].innerText).toEqual('blue');

      click('.answer-set-tabs button:contains("size")');

      expect(find('.answer-set-tabs .active').innerText).toMatch('size');
      answerTextMatches = findAll("th.answer-textfield");
      expect(answerTextMatches[0].innerText).toEqual('S');
      expect(answerTextMatches[1].innerText).toEqual('M');
      expect(answerTextMatches[2].innerText).toEqual('L');
    });
  });
});

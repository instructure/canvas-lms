define(function(require) {
  var Subject = require('jsx!views/questions/answer_table');
  var $ = require('canvas_packages/jquery');
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var d3 = require('d3');

  describe('Views.Questions.AnswerTable', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should show the right number of answer bars', function() {
      var rect;

      setProps({
        answers: [
          { id: '1', correct: true, responses: 4, ratio: 4/6.0 },
          { id: '2', correct: false, responses: 2, ratio: 2/6.0 },
        ]
      });

      expect(findAll('div.bar').length).toBe(2);
    });
  });
});
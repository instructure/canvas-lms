define(function(require) {
  var Subject = require('models/quiz_statistics');
  var fixture = require('json!fixtures/quiz_statistics_all_types.json');

  describe('Models.QuizStatistics', function() {
    it('should parse properly', function() {
      var subject = new Subject(fixture.quiz_statistics[0], { parse: true });

      expect(subject.get('id')).toBe('267');
      expect(subject.get('pointsPossible')).toBe(16);

      expect(typeof subject.get('submissionStatistics')).toBe('object');
      expect(subject.get('submissionStatistics').uniqueCount).toBe(156);
      expect(subject.get('questionStatistics').length).toBe(13);
    });

    it('should parse the discrimination index', function() {
      var subject = new Subject(fixture.quiz_statistics[0], { parse: true });

      expect(subject.get('id')).toBe('267');
      expect(subject.get('questionStatistics')[0].discriminationIndex).toBe(0.7157094891780442);
    });

    describe('calculating participant count', function() {
      it('should use the number of students who actually took the question', function() {
        var subject = new Subject({
          question_statistics: [
            {
              question_type: 'multiple_choice_question',
              answers: [
                { id: '1', responses: 2 },
                { id: '2', responses: 3 }
              ]
            }
          ]
        }, { parse: true });

        expect(subject.get('questionStatistics')[0].participantCount).toEqual(5);
      });

      it('should work with questions that have answer sets', function() {
        var subject = new Subject({
          question_statistics: [
            {
              question_type: 'fill_in_multiple_blanks_question',
              answer_sets: [
                {
                  id: 'some answer set',
                  answers: [
                    { id: '1', responses: 2 },
                    { id: '2', responses: 3 }
                  ]
                },
                {
                  id: 'some other answer set',
                  answers: [
                    { id: '3', responses: 0 },
                    { id: '4', responses: 5 }
                  ]
                }
              ]
            }
          ]
        }, { parse: true });

        expect(subject.get('questionStatistics')[0].participantCount).toEqual(5);
      });

      it("should work with multiple_answers_questions", function() {
        var subject = new Subject({
          question_statistics: [
            {
              question_type:"multiple_answers_question",
              responses:2,
              correct:1,
              answers:[
                {id:"6122",text:"a",correct:true,responses:2},
                {id:"6863",text:"b",correct:true,responses:2},
                {id:"3938",text:"c",correct:true,responses:2},
                {id:"938",text:"d",correct:false,responses:1}
              ]
            }
          ]
        }, {parse: true});

        expect(subject.get("questionStatistics")[0].participantCount).toEqual(2);
      });
    });
  });
});
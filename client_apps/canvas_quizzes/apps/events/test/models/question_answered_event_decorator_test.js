define(function(require) {
  var Subject = require('models/question_answered_event_decorator');
  var Backbone = require('canvas_packages/backbone');
  var _ = require('lodash');
  var findWhere = _.findWhere;

  describe('Models.QuestionAnsweredEventDecorator', function() {
    describe('#decorateAnswerRecord', function() {
      describe('inferring whether a question is answered', function() {
        var record = {};
        var questionType;
        var subject = function(answer) {
          record.answer = answer;

          return Subject.decorateAnswerRecord({
            questionType: questionType
          }, record);
        };

        it('multiple_choice_question and many friends (scalar answers)', function() {
          questionType = 'multiple_choice_question';

          subject(null);
          expect(record.answered).toEqual(false);

          subject('123');
          expect(record.answered).toEqual(true);
        });

        it('fill_in_multiple_blanks_question, multiple_dropdowns', function() {
          questionType = 'fill_in_multiple_blanks_question';

          subject({ color1: null, color2: null });
          expect(record.answered).toEqual(false, 'should be false when all blanks are nulls');

          subject({ color1: 'something', color2: null });
          expect(record.answered).toEqual(true, 'should be true if any blank is filled with anything');
        });

        it('matching_question', function() {
          questionType = 'matching_question';

          subject([]);
          expect(record.answered).toEqual(false);

          subject(null);
          expect(record.answered).toEqual(false);

          subject([{ answer_id: '123', match_id: null }]);
          expect(record.answered).toEqual(false);

          subject([{ answer_id: '123', match_id: '456' }]);
          expect(record.answered).toEqual(true);
        });

        it('multiple_answers, file_upload', function() {
          questionType = 'matching_question';

          subject([]);
          expect(record.answered).toEqual(false);

          subject(null);
          expect(record.answered).toEqual(false);

          subject(null);
          expect(record.answered).toEqual(false);

        });
      });
    });

    describe('#run', function() {
      it('should mark latest answers to all questions', function() {
        var events = [
          {
            data: [
              { quizQuestionId: '1', answer: 'something' },
              { quizQuestionId: '2', answer: null }
            ]
          },
          {
            data: [
              { quizQuestionId: '1', answer: 'something else' }
            ]
          }
        ];

        var eventCollection = events.map(function(attrs) {
          return new Backbone.Model(attrs);
        });

        var questions = [
          { id: '1' },
          { id: '2' }
        ];

        var findQuestionRecord = function(eventIndex, id) {
          return findWhere(eventCollection[eventIndex].get('data'), {
            quizQuestionId: id
          });
        };

        Subject.run(eventCollection, questions);

        expect(findQuestionRecord(0, '1').last).toBeFalsy();
        expect(findQuestionRecord(1, '1').last).toBeTruthy();

        expect(findQuestionRecord(0, '2').last).toBeTruthy();
      });
    });
  });
});
define(function(require) {
  var Subject = require('jsx!views/app');
  var Statistics = require('stores/statistics');
  var _ = require('lodash');

  describe('Views.App', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    describe('detail visibility', function() {
      it('should expand details of all questions', function() {
        Statistics.populate({
          quiz_statistics: [{
            question_statistics: [{
              id: '1'
            }]
          }]
        })

        setProps({
          quizStatistics: Statistics.get()
        });

        expect(function() {
          click('.all-question-controls .btn .icon-expand');
        }).toSendAction('statistics:expandAll');
      });

      it('should collapse details of all questions', function() {
        Statistics.populate({
          quiz_statistics: [{
            question_statistics: [{
              id: '1',
              question_type: 'multiple_choice_question'
            }]
          }]
        })

        setProps({
          quizStatistics: _.extend(Statistics.get(), { expandingAll: true })
        });

        expect(function() {
          click('.all-question-controls .btn .icon-collapse');
        }).toSendAction('statistics:collapseAll');
      });

      it('should expand details of a single question', function() {
        Statistics.populate({
          quiz_statistics: [{
            question_statistics: [{
              id: '1',
              question_type: 'multiple_choice_question'
            }]
          }]
        })

        setProps({
          quizStatistics: Statistics.get()
        });

        expect(function() {
          click('.question-statistics .btn .icon-expand');
        }).toSendAction('statistics:expandQuestion', '1');
      });

      it('should collapse details of a single question', function() {
        Statistics.populate({
          quiz_statistics: [{
            question_statistics: [{
              id: '1',
              question_type: 'multiple_choice_question'
            }]
          }]
        })

        setProps({
          quizStatistics: _.extend(Statistics.get(), { expanded: [ '1' ] })
        });

        expect(function() {
          click('.question-statistics .btn .icon-collapse');
        }).toSendAction('statistics:collapseQuestion', '1');
      });
    });

  });
});
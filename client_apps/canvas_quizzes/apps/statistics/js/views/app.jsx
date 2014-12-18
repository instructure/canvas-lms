/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var I18n = require('i18n!quiz_statistics');
  var Notifications = require('jsx!canvas_quizzes/views/notifications');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var Summary = require('jsx!./summary');
  var ToggleDetailsButton = require('jsx!./questions/toggle_details_button');
  var QuestionRenderer = require('jsx!./question');
  var MultipleChoiceRenderer = require('jsx!./questions/multiple_choice');
  var ShortAnswerRenderer = require('jsx!./questions/short_answer');
  var FillInMultipleBlanksRenderer = require('jsx!./questions/fill_in_multiple_blanks');
  var EssayRenderer = require('jsx!./questions/essay');
  var CalculatedRenderer = require('jsx!./questions/calculated');
  var FileUploadRenderer = require('jsx!./questions/file_upload');

  var extend = _.extend;
  var Renderers = {
    'multiple_choice_question': MultipleChoiceRenderer,
    'true_false_question': MultipleChoiceRenderer,
    'short_answer_question': ShortAnswerRenderer,
    'multiple_answers_question': ShortAnswerRenderer,
    'numerical_question': ShortAnswerRenderer,
    'fill_in_multiple_blanks_question': FillInMultipleBlanksRenderer,
    'multiple_dropdowns_question': FillInMultipleBlanksRenderer,
    'matching_question': FillInMultipleBlanksRenderer,
    'essay_question': EssayRenderer,
    'calculated_question': CalculatedRenderer,
    'file_upload_question': FileUploadRenderer,
  };

  var Statistics = React.createClass({
    mixins: [ React.addons.ActorMixin ],

    getDefaultProps: function() {
      return {
        quizStatistics: {
          submissionStatistics: {},
          questionStatistics: [],
        },

        notifications: []
      };
    },

    render: function() {
      var props = this.props;
      var quizStatistics = this.props.quizStatistics;
      var submissionStatistics = quizStatistics.submissionStatistics;

      return(
        <div id="canvas-quiz-statistics">
          <ScreenReaderContent tagName="h1">
            {I18n.t('title', 'Quiz Statistics')}
          </ScreenReaderContent>

          <Notifications notifications={this.props.notifications} />

          <section>
            <Summary
              pointsPossible={quizStatistics.pointsPossible}
              scoreAverage={submissionStatistics.scoreAverage}
              scoreHigh={submissionStatistics.scoreHigh}
              scoreLow={submissionStatistics.scoreLow}
              scoreStdev={submissionStatistics.scoreStdev}
              durationAverage={submissionStatistics.durationAverage}
              quizReports={this.props.quizReports}
              scores={submissionStatistics.scores}
              loading={this.props.isLoadingStatistics}
              />
          </section>

          <section id="question-statistics-section">
            <header className="padded">
              <h2 className="section-title inline">
                {I18n.t('question_breakdown', 'Question Breakdown')}
              </h2>

              <aside className="all-question-controls pull-right">
                <SightedUserContent tagName="div">
                  <ToggleDetailsButton
                    onClick={this.toggleAllDetails}
                    expanded={quizStatistics.expandingAll}
                    disabled={this.props.isLoadingStatistics}
                    controlsAll />
                </SightedUserContent>
              </aside>
            </header>

            {this.renderQuestions()}
          </section>
        </div>
      );
    },

    renderQuestions: function() {
      var isLoadingStatistics = this.props.isLoadingStatistics;
      var questionStatistics = this.props.quizStatistics.questionStatistics;
      var participantCount = this.props.quizStatistics.submissionStatistics.uniqueCount;

      if (isLoadingStatistics) {
        return (
          <p>
            {I18n.t('loading_questions',
              'Question statistics are being loaded. Please wait a while.')}
          </p>
        );
      }
      else if (questionStatistics.length === 0) {
        return (
          <p>
            {I18n.t('empty_question_breakdown', 'There are no question statistics available.')}
          </p>
        );
      }
      else {
        return (
          <div>
            {questionStatistics.map(this.renderQuestion.bind(null, participantCount))}
          </div>
        );
      }
    },

    renderQuestion: function(participantCount, question) {
      var renderer = Renderers[question.questionType] || QuestionRenderer;
      var stats = this.props.quizStatistics;
      var questionProps = extend({}, question, {
        key: 'question-' + question.id,
        participantCount: question.participantCount,
        expanded: stats.expanded.indexOf(question.id) > -1,
        speedGraderUrl: stats.speedGraderUrl,
        quizSubmissionsZipUrl: stats.quizSubmissionsZipUrl,
        onToggleDetails: this.toggleDetails.bind(null, question.id)
      });

      return renderer(questionProps);
    },

    toggleDetails: function(questionId, e) {
      e.preventDefault();

      if (this.props.quizStatistics.expanded.indexOf(questionId) !== -1) {
        this.sendAction('statistics:collapseQuestion', questionId);
      }
      else {
        this.sendAction('statistics:expandQuestion', questionId);
      }
    },

    toggleAllDetails: function(e) {
      e.preventDefault();

      if (this.props.quizStatistics.expandingAll) {
        this.sendAction('statistics:collapseAll');
      }
      else {
        this.sendAction('statistics:expandAll');
      }
    }
  });

  return Statistics;
});
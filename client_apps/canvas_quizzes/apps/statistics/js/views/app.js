/** @jsx React.DOM */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var _ = require('lodash');
  var I18n = require('i18n!quiz_statistics');
  var Notifications = require('jsx!./notifications');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var Summary = require('jsx!./summary');
  var Report = require('jsx!./summary/report');
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
      var quizStatistics = this.props.quizStatistics;
      var submissionStatistics = quizStatistics.submissionStatistics;
      if (!this.props.canBeLoaded) {
        return(
          <div id="canvas-quiz-statistics" className="canvas-quiz-statistics-noload">
            <div id="sad-panda">
              <img src="/images/sadpanda.svg"
                alttext={I18n.t('sad-panda-alttext', "Sad things in panda land.")}
                />
              <p>
                {I18n.t("quiz-stats-noshow-warning", "Even awesomeness has limits. We can't render statistics for this quiz, but you can download the reports.")}
              </p>
              <div className="links">
                {this.renderQuizReports(this.props.quizReports)}
              </div>
            </div>
          </div>
        );
      } else {
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
              </header>

              {this.renderQuestions()}
            </section>
          </div>
        );
      }
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

    renderQuizReports: function() {
      var quizReports = this.props.quizReports;
      if (typeof quizReports !== "undefined" && quizReports !== null && quizReports.length) {
        return quizReports.map(this.renderReport);
      }
    },
    renderReport: function(reportProps) {
      reportProps.key = "report-" + reportProps.id;
      return Report(reportProps);
    },

    renderQuestion: function(participantCount, question) {
      var renderer = Renderers[question.questionType] || QuestionRenderer;
      var stats = this.props.quizStatistics;
      var questionProps = extend({}, question, {
        key: 'question-' + question.id,
        participantCount: question.participantCount,
        speedGraderUrl: stats.speedGraderUrl,
        quizSubmissionsZipUrl: stats.quizSubmissionsZipUrl,
      });

      return renderer(questionProps);
    }
  });

  return Statistics;
});

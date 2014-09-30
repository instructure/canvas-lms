/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_reports');
  var DateTimeHelpers = require('../../../util/date_time_helpers');
  var friendlyDatetime = DateTimeHelpers.friendlyDatetime;
  var fudgeDateForProfileTimezone = DateTimeHelpers.fudgeDateForProfileTimezone;

  var Status = React.createClass({
    getDefaultProps: function() {
      return {
        generatable: true,
        file: {},
        progress: {}
      };
    },

    render: function() {
      var body, generatedAt;

      if (!this.props.generatable) {
        body = I18n.t('non_generatable_report_notice',
          'Report can not be generated for Survey Quizzes.');
      }
      else if (this.props.isGenerated) {
        generatedAt = friendlyDatetime(fudgeDateForProfileTimezone(this.props.file.createdAt));

        body = I18n.t('generated_at', 'Generated at %{date}', {
          date: generatedAt
        });
      }
      else if (this.isGenerating()) {
        body = this.renderProgress();
      } else {
        body = I18n.t('generatable', 'Report has never been generated.');
      }

      return (
        <div className="quiz-report-status">
          {body}
        </div>
      );
    },

    isGenerating: function() {
      var workflowState = this.props.progress.workflowState;
      return [ 'queued', 'running' ].indexOf(workflowState) > -1;
    },

    renderProgress: function() {
      return (
        <div className="auxiliary">
          <p>{I18n.t('generating', 'Report is being generated...')}</p>
          <div className="progress">
            <div className="bar" style={{
              width: (this.props.progress.completion || 0) + '%'
            }}></div>
          </div>
        </div>
      );
    }
  });

  return Status;
});
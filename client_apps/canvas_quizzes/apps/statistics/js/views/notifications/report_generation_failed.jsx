/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Text = require('jsx!canvas_quizzes/components/text');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_reports');
  var Actions = require('../../actions');
  var Descriptor = require('../../models/quiz_report_descriptor');
  var Alert = require('jsx!canvas_quizzes/components/alert');

  var Notification = React.createClass({
    statics: {
      code: K.NOTIFICATION_REPORT_GENERATION_FAILED
    },

    getDefaultProps: function() {
      return {
      };
    },

    render: function() {
      var readableReportType = Descriptor.getLabel(this.props.reportType);
      var report_type;

      return(
        <Alert autoFocus type="danger" onClick={this.retryOrCancel}>
          <Text
            phrase="notifications.report_generation_failed"
            reportType={readableReportType}>
            It looks like something went wrong while generating the {"%{report_type}"} report.

            You may want to <a href='#' data-action="retry">retry</a> the operation,
            or <a href='#' data-action="abort">cancel</a> it completely.
          </Text>
        </Alert>
      );
    },

    retryOrCancel: function(e) {
      if (e.target.nodeName === 'A') {
        switch (e.target.dataset.action) {
          case 'retry':
            Actions.regenerateReport(this.props.reportId);
          break;

          case 'abort':
            Actions.abortReportGeneration(this.props.reportId);
          break;
        }
      }
    }
  });

  return Notification;
});
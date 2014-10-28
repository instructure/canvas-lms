define(function(require) {
  var QuizReports = require('../stores/reports');
  var Notification = require('../models/notification');
  var K = require('../constants');

  // Notify the teacher of failures during CSV report generation.
  var watchForReportGenerationFailures = function() {
    return QuizReports.getAll().filter(function(report) {
      if (!!report.progress) {
        return report.progress.workflowState === K.PROGRESS_FAILED;
      }
    }).map(function(report) {
      return new Notification({
        id: [ 'reports', report.id, report.progress.id ].join('_'),
        code: K.NOTIFICATION_REPORT_GENERATION_FAILED,
        context: {
          reportId: report.id,
          reportType: report.reportType
        }
      });
    });
  };

  watchForReportGenerationFailures.watchTargets = [ QuizReports ];

  return watchForReportGenerationFailures;
});
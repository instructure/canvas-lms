define((require) => {
  const QuizReports = require('../stores/reports');
  const Notification = require('canvas_quizzes/models/notification');
  const K = require('../constants');

  // Notify the teacher of failures during CSV report generation.
  const watchForReportGenerationFailures = function () {
    return QuizReports.getAll().filter((report) => {
      if (report.progress) {
        return report.progress.workflowState === K.PROGRESS_FAILED;
      }
    }).map(report => new Notification({
      id: ['reports', report.id, report.progress.id].join('_'),
      code: K.NOTIFICATION_REPORT_GENERATION_FAILED,
      context: {
        reportId: report.id,
        reportType: report.reportType
      }
    }));
  };

  watchForReportGenerationFailures.watchTargets = [QuizReports];

  return watchForReportGenerationFailures;
});

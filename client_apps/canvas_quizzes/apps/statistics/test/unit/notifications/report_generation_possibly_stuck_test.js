define(function(require) {
  var Subject = require('notifications/report_generation_failed');
  var K = require('constants');
  var QuizReports = require('stores/reports');

  describe('Notifications::ReportGenerationFailed', function() {
    it('should work', function() {
      var notifications = Subject();

      expect(notifications.length).toBe(0);

      QuizReports.populate({
        quiz_reports: [{
          id: '1',
          report_type: 'student_analysis',
          progress: {
            url: '/progress/1',
            workflow_state: K.PROGRESS_FAILED,
            completion: 40
          }
        }]
      });

      notifications = Subject();
      expect(notifications.length).toBe(1);
      expect(notifications[0].context.reportType).toEqual('student_analysis',
        'it attaches the report type');
    });
  });
});
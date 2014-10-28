define(function(require) {
  var Subject = require('jsx!views/notifications/report_generation_failed');
  var Actions = require('actions');

  describe('Views.Notifications.ReportGenerationFailed', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('should trigger a retry', function() {
      var spy = spyOn(Actions, 'regenerateReport');

      setProps({
        reportType: 'student_analysis'
      });

      click('a[data-action="retry"]', true);

      expect(spy).toHaveBeenCalled();
    });

    it('should trigger an abort', function() {
      var spy = spyOn(Actions, 'abortReportGeneration');

      setProps({
        reportType: 'student_analysis'
      });

      click('a[data-action="abort"]', true);

      expect(spy).toHaveBeenCalled();
    });
  });
});
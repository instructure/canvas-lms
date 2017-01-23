define((require) => {
  const Subject = require('jsx!views/notifications/report_generation_failed');
  const Actions = require('actions');

  describe('Views.Notifications.ReportGenerationFailed', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {});
    it('should trigger a retry', () => {
      const spy = spyOn(Actions, 'regenerateReport');

      setProps({
        reportType: 'student_analysis'
      });

      click('a[data-action="retry"]', true);

      expect(spy).toHaveBeenCalled();
    });

    it('should trigger an abort', () => {
      const spy = spyOn(Actions, 'abortReportGeneration');

      setProps({
        reportType: 'student_analysis'
      });

      click('a[data-action="abort"]', true);

      expect(spy).toHaveBeenCalled();
    });
  });
});

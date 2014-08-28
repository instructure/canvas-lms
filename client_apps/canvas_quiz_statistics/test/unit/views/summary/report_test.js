define(function(require) {
  var Subject = require('jsx!views/summary/report');

  describe('Views.Summary.Report', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {});
    it('should be a button if it can be generated', function() {
      setProps({ generatable: true });

      expect('> button').toExist();
    });

    it('should be an anchor if it can be downloaded', function() {
      setProps({ generatable: false });

      expect('> a').toExist();
    });

    it('should generate a report', function() {
      setProps({
        generatable: true,
        reportType: 'student_analysis'
      });

      expect(function() {
        click('button.generate-report');
      }).toSendAction({
        action: 'statistics:generateReport',
        args: 'student_analysis'
      });
    });
  });
});
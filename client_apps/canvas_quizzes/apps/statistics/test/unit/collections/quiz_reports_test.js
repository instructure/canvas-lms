define(function(require) {
  var Subject = require('collections/quiz_reports');
  describe('Collections.QuizReports', function() {
    it('should parse properly', function() {
      var fixture = require('json!fixtures/quiz_reports.json');
      var subject = new Subject();
      subject.add(fixture, { parse: true });

      expect(subject.length).toBe(2);
      expect(subject.first().get('id')).toBe('200');
      expect(subject.first().get('reportType')).toBe('student_analysis');
    });
  });
});
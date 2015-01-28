define(function(require) {
  var Subject = require('models/quiz_report');
  describe('Models.QuizReport', function() {
    it('should parse properly', function() {
      var fixture = require('json!fixtures/quiz_reports.json');
      var subject = new Subject(fixture.quiz_reports[0], { parse: true });

      expect(subject.get('id')).toBe('200');
      expect(subject.get('reportType')).toBe('student_analysis');
    });
  });
});
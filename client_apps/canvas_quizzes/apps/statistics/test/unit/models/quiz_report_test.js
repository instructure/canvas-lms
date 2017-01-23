define((require) => {
  const Subject = require('models/quiz_report');
  describe('Models.QuizReport', () => {
    it('should parse properly', () => {
      const fixture = require('json!fixtures/quiz_reports.json');
      const subject = new Subject(fixture.quiz_reports[0], { parse: true });

      expect(subject.get('id')).toBe('200');
      expect(subject.get('reportType')).toBe('student_analysis');
    });
  });
});

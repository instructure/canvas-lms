define((require) => {
  const Subject = require('collections/quiz_reports');
  describe('Collections.QuizReports', () => {
    it('should parse properly', () => {
      const fixture = require('json!fixtures/quiz_reports.json');
      const subject = new Subject();
      subject.add(fixture, { parse: true });

      expect(subject.length).toBe(2);
      expect(subject.first().get('id')).toBe('200');
      expect(subject.first().get('reportType')).toBe('student_analysis');
    });
  });
});

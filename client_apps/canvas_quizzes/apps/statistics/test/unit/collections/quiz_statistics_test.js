define((require) => {
  const Subject = require('collections/quiz_statistics');
  describe('Collections.QuizStatistics', () => {
    it('should parse from "payload.quiz_statistics"', () => {
      const fixture = require('json!fixtures/quiz_statistics_all_types.json');
      const subject = new Subject();
      subject.add(fixture, { parse: true });

      expect(subject.length).toBe(1);
      expect(subject.first().get('id')).toBe('267');
    });
  });
});

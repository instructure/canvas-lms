define(function(require) {
  var Subject = require('collections/quiz_statistics');
  describe('Collections.QuizStatistics', function() {
    it('should parse from "payload.quiz_statistics"', function() {
      var fixture = require('json!fixtures/quiz_statistics_all_types.json');
      var subject = new Subject();
      subject.add(fixture, { parse: true });

      expect(subject.length).toBe(1);
      expect(subject.first().get('id')).toBe('200');
    });
  });
});
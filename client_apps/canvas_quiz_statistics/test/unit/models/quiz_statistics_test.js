define(function(require) {
  var Subject = require('models/quiz_statistics');
  var fixture = require('json!fixtures/quiz_statistics_all_types.json');

  describe('Models.QuizStatistics', function() {
    it('should parse properly', function() {
      var subject = new Subject(fixture.quiz_statistics[0], { parse: true });

      expect(subject.get('id')).toBe('200');
      expect(subject.get('pointsPossible')).toBe(16);

      expect(typeof subject.get('submissionStatistics')).toBe('object');
      expect(subject.get('submissionStatistics').uniqueCount).toBe(6);
      expect(subject.get('questionStatistics').length).toBe(13);
    });

    it('should parse the discrimination index', function() {
      var subject = new Subject(fixture.quiz_statistics[0], { parse: true });

      expect(subject.get('id')).toBe('200');
      expect(subject.get('questionStatistics')[0].discriminationIndex).toBe(-0.0473037765270769);
    });
  });
});
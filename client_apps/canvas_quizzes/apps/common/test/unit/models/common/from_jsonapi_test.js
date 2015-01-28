define(function(require) {
  var subject = require('canvas_quizzes/models/common/from_jsonapi');
  describe('Models.Common.fromJSONAPI', function() {
    it('should extract a set', function() {
      var output = subject({
        quiz_reports: [{
          id: '1'
        }]
      }, 'quiz_reports');

      expect(Array.isArray(output)).toBe(true);
      expect(output[0].id).toBe('1');
    });

    it('should extract a set from a flat payload', function() {
      var output = subject([{
        id: '1'
      }], 'quiz_reports');

      expect(Array.isArray(output)).toBe(true);
      expect(output[0].id).toBe('1');
    });

    it('should extract a single object', function() {
      var output = subject({
        quiz_reports: [{
          id: '1'
        }]
      }, 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });

    it('should extract a single object from a flat array payload', function() {
      var output = subject([{
        id: '1'
      }], 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });

    it('should extract a single object from a flat object payload', function() {
      var output = subject({
        id: '1'
      }, 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });

  });
});
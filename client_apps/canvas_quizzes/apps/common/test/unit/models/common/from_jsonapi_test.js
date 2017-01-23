define((require) => {
  const subject = require('canvas_quizzes/models/common/from_jsonapi');
  describe('Models.Common.fromJSONAPI', () => {
    it('should extract a set', () => {
      const output = subject({
        quiz_reports: [{
          id: '1'
        }]
      }, 'quiz_reports');

      expect(Array.isArray(output)).toBe(true);
      expect(output[0].id).toBe('1');
    });

    it('should extract a set from a flat payload', () => {
      const output = subject([{
        id: '1'
      }], 'quiz_reports');

      expect(Array.isArray(output)).toBe(true);
      expect(output[0].id).toBe('1');
    });

    it('should extract a single object', () => {
      const output = subject({
        quiz_reports: [{
          id: '1'
        }]
      }, 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });

    it('should extract a single object from a flat array payload', () => {
      const output = subject([{
        id: '1'
      }], 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });

    it('should extract a single object from a flat object payload', () => {
      const output = subject({
        id: '1'
      }, 'quiz_reports', true);

      expect(Array.isArray(output)).toBe(false);
      expect(output.id).toBe('1');
    });
  });
});

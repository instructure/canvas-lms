define(function(require) {
  var Subject = require('jsx!views/summary/section_select');

  describe('SectionSelect', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

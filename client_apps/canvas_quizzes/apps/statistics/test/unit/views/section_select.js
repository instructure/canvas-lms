define((require) => {
  const Subject = require('jsx!views/summary/section_select');

  describe('SectionSelect', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

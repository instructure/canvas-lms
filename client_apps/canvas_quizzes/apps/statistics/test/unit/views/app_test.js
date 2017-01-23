define((require) => {
  const Subject = require('jsx!views/app');
  const Statistics = require('stores/statistics');
  const _ = require('lodash');

  describe('Views.App', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

define((require) => {
  const Subject = require('jsx!views/session');

  describe('Views::Session', function () {
    const suite = reactRouterSuite(this, Subject, {});

    suite.stubRoutes([
      { name: 'answer_matrix', path: '/doesnt_matter' }
    ]);

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });
  });
});

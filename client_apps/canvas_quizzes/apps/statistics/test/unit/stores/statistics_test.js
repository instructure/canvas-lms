define((require) => {
  const subject = require('stores/statistics');
  const config = require('config');
  const quizStatisticsFixture = require('json!fixtures/quiz_statistics_all_types.json');

  describe('Stores.Statistics', function () {
    this.storeSuite(subject);

    beforeEach(() => {
      config.quizStatisticsUrl = '/stats';
    });

    describe('#load', function () {
      this.xhrSuite = true;

      it('should load and deserialize stats', function () {
        let quizStats,
          quizReports;

        this.respondWith('GET', '/stats', xhrResponse(200, quizStatisticsFixture));

        subject.addChangeListener(onChange);
        subject.load();
        this.respond();

        quizStats = subject.get();

        expect(quizStats).toBeTruthy();
        expect(quizStats.id).toEqual('267');

        expect(onChange).toHaveBeenCalled();
      });
    });
  });
});

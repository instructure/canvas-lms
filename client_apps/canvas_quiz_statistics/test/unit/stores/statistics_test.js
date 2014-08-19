define(function(require) {
  var subject = require('stores/statistics');
  var config = require('config');
  var quizStatisticsFixture = require('json!fixtures/quiz_statistics_all_types.json');

  describe('Stores.Statistics', function() {
    this.storeSuite(subject);

    beforeEach(function() {
      config.quizStatisticsUrl = '/stats';
    });

    describe('#load', function() {
      this.xhrSuite = true;

      it('should load and deserialize stats', function() {
        var quizStats, quizReports;

        this.respondWith('GET', '/stats', xhrResponse(200, quizStatisticsFixture));

        subject.addChangeListener(onChange);
        subject.load();
        this.respond();

        quizStats = subject.get();

        expect(quizStats).toBeTruthy();
        expect(quizStats.id).toEqual('200');

        expect(onChange).toHaveBeenCalled();
      });
    });
  });
});
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

    describe('statistics:expandQuestion', function() {
      it('should work', function() {
        subject.populate(quizStatisticsFixture);
        this.sendAction('statistics:expandQuestion', '11');

        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet()).toEqual(['11']);
      });
    });

    describe('statistics:collapseQuestion', function() {
      it('should work', function() {
        subject.populate(quizStatisticsFixture);
        this.sendAction('statistics:collapseQuestion', '11');

        expect(onChange).not.toHaveBeenCalled();

        this.sendAction('statistics:expandQuestion', '11');
        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet()).toEqual(['11']);

        onChange.calls.reset();

        this.sendAction('statistics:collapseQuestion', '11');
        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet()).toEqual([]);
      });
    });

    describe('statistics:expandAll', function() {
      it('should work', function() {
        subject.populate(quizStatisticsFixture);
        this.sendAction('statistics:expandAll');

        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet().length).toEqual(13);
      });
    });

    describe('statistics:collapseAll', function() {
      it('should work', function() {
        subject.populate(quizStatisticsFixture);

        this.sendAction('statistics:expandQuestion', '11');
        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet()).toEqual(['11']);

        onChange.calls.reset();

        this.sendAction('statistics:collapseAll');
        expect(onChange).toHaveBeenCalled();
        expect(subject.getExpandedSet().length).toEqual(0);
      });
    });
  });
});
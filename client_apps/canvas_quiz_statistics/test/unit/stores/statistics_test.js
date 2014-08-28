define(function(require) {
  var Subject = require('stores/statistics');
  var RSVP = require('rsvp');
  var Adapter = require('core/adapter');
  var config = require('config');
  var _ = require('lodash');
  var quizStatisticsFixture = require('json!fixtures/quiz_statistics_all_types.json');
  var quizReportsFixture = require('json!fixtures/quiz_reports.json');
  var mapBy = _.map;

  describe('Stores.Statistics', function() {
    this.promiseSuite = true;

    beforeEach(function() {
      config.quizStatisticsUrl = '/stats';
      config.quizReportsUrl = '/reports';
    });

    afterEach(function() {
      Subject.__reset__();
    });

    describe('#load', function() {
      this.xhrSuite = true;

      it('should load and deserialize stats and reports', function() {
        var onChange = jasmine.createSpy('onChange');
        var quizStats, quizReports;

        this.respondWith('GET', '/stats', xhrResponse(200, quizStatisticsFixture));
        this.respondWith('GET', '/reports', xhrResponse(200, quizReportsFixture));

        Subject.addChangeListener(onChange);
        Subject.load();
        this.respond();

        quizStats = Subject.getQuizStatistics();
        quizReports = Subject.getQuizReports();

        expect(quizStats).toBeTruthy();
        expect(quizStats.id).toEqual('200');

        expect(quizReports.length).toBe(2);
        expect(mapBy(quizReports, 'id').sort()).toEqual([ '200', '201' ]);

        expect(onChange).toHaveBeenCalled();
      });
    });

    describe('actions.generateReport', function() {
      this.xhrSuite = {
        trackRequests: true
      };

      it('should work', function() {
        var onChange = jasmine.createSpy('onChange');
        var onError = jasmine.createSpy('onError');

        // TODO: some better interface for testing actions pls
        Subject.actions.generateReport.call(Subject, 'student_analysis', onChange, onError);

        expect(this.requests.length).toBe(1);
        expect(this.lastRequest.url).toBe('/reports');
        expect(this.lastRequest.method).toBe('POST');
        expect(this.lastRequest.requestBody).toEqual(JSON.stringify({
          quiz_reports: [{
            report_type: 'student_analysis',
            includes_all_versions: true
          }],
          include: [ 'progress', 'file' ]
        }));

        this.respondTo(this.lastRequest, 200, {}, {
          quiz_reports: [{
            id: '200',
            progress: {
              workflow_state: 'foobar'
            }
          }]
        });

        expect(Subject.getQuizReports()[0].progress.workflowState).toBe('foobar');

        expect(onChange).toHaveBeenCalled();
      });
    })
  });
});
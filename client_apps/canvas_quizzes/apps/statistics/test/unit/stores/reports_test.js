define(function(require) {
  var subject = require('stores/reports');
  var config = require('config');
  var quizReportsFixture = require('json!fixtures/quiz_reports.json');
  var K = require('constants');

  describe('Stores.Reports', function() {
    this.storeSuite(subject);

    beforeEach(function() {
      config.quizReportsUrl = '/reports';
    });

    describe('#load', function() {
      this.xhrSuite = true;

      it('should load and deserialize reports', function() {
        var quizReports;

        this.respondWith('GET', /^\/reports/, xhrResponse(200, quizReportsFixture));

        subject.addChangeListener(onChange);
        subject.load();
        this.respond();

        quizReports = subject.getAll();

        expect(quizReports.length).toBe(2);
        expect(quizReports.map(function(quizReport) {
          return quizReport.id;
        }).sort()).toEqual([ '200', '201' ]);

        expect(onChange).toHaveBeenCalled();
      });

      it('should request both "file" and "progress" to be included with quiz reports', function() {
        var quizReportsUrl;

        subject.load();

        expect(this.server.requests.length).toBe(1);

        quizReportsUrl = decodeURI(this.server.requests[0].url);
        expect(quizReportsUrl).toBe('/reports?include[]=progress&include[]=file&includes_all_versions=true');
      });
    });

    describe('#populate', function() {
      this.xhrSuite = {
        trackRequests: true
      };

      it('should track any active reports being generated', function() {
        subject.populate({
          quiz_reports: [{
            id: '1',
            progress: {
              url: '/progress/1',
              workflow_state: K.PROGRESS_ACTIVE,
              completion: 40
            }
          }]
        }, { track: true });

        expect(this.requests.length).toBe(1);
        expect(this.requests[0].url).toBe('/progress/1');
      });

      it('but it should not auto-download them when generated', function() {
        subject.populate({
          quiz_reports: [{
            id: '1',
            progress: {
              url: '/progress/1',
              workflow_state: K.PROGRESS_ACTIVE,
              completion: 40
            }
          }]
        }, { track: true });

        expect(this.requests.length).toBe(1);
        expect(this.requests[0].url).toBe('/progress/1');

        this.respondTo(this.requests[0], 200, {
          workflow_state: K.PROGRESS_COMPLETE,
          completion: 100
        });

        expect(this.requests.length).toBe(2);
        expect(this.requests[1].url).toContain('/reports/1');

        this.respondTo(this.requests[1], 200, {
          quiz_reports: [{
            id: '1',
            file: {
              url: '/files/1/download'
            }
          }]
        });

        expect(this.requests.length).toBe(2);
        expect(document.body.querySelector('iframe'))
          .toBeFalsy('it should not create an <iframe /> for auto-downloading');
      });

      it('should never track the same report multiple times simultaneously', function() {
        subject.populate({
          quiz_reports: [{
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/foobar'
            }
          }]
        }, { track: true });

        expect(this.requests.length).toBe(1);

        subject.populate({
          quiz_reports: [{
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/foobar'
            }
          }]
        }, { track: true });

        expect(this.requests.length).toBe(1);

        subject.populate({
          quiz_reports: [{
            id: '2',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/foobar'
            }
          }]
        }, { track: true });

        expect(this.requests.length).toBe(2);
      });
    });

    describe('quizReports:generate', function() {
      this.xhrSuite = {
        trackRequests: true
      };

      it('should work', function() {
        this.sendAction('quizReports:generate', 'student_analysis');

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

        expect(subject.getAll()[0].progress.workflowState).toBe('foobar');
        expect(onChange).toHaveBeenCalled();
      });

      it('should track the generation progress', function() {
        this.sendAction('quizReports:generate', 'student_analysis');

        expect(this.requests.length).toBe(1);
        expect(this.requests[0].url).toBe('/reports');

        this.respondTo(this.requests[0], 200, {}, {
          quiz_reports: [{
            id: '1',
            progress: {
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/progress/1'
            }
          }]
        });

        expect(this.requests.length).toBe(2);
        expect(this.requests[1].url).toBe('/progress/1');
        expect(onChange).toHaveBeenCalled();
      });

      it('should auto download the file when generated', function() {
        this.sendAction('quizReports:generate', 'student_analysis');

        expect(this.requests.length).toBe(1);
        expect(this.requests[0].url).toBe('/reports');

        this.respondTo(this.requests[0], 200, {}, {
          quiz_reports: [{
            id: '1',
            progress: {
              workflow_state: 'running',
              url: '/progress/1'
            }
          }]
        });

        expect(this.requests.length).toBe(2);
        expect(this.requests[1].url).toBe('/progress/1');

        this.respondTo(this.requests[1], 200, {}, {
          workflow_state: K.PROGRESS_COMPLETE,
          completion: 100
        });

        expect(this.requests.length).toBe(3);
        expect(this.requests[2].url).toContain('/reports/1?include%5B%5D=progress');

        this.respondTo(this.requests[2], 200, {}, {
          quiz_reports: [{
            id: '1',
            file: {
              url: '/files/1/download'
            }
          }]
        });

        var iframe = document.body.querySelector('iframe');

        expect(iframe).toBeTruthy();
        expect(iframe.src).toContain('/files/1/download');
        expect(iframe.style.display).toBe('none');

        expect(onChange).toHaveBeenCalled();
      });

      it('should reject if the report is being generated', function() {
        subject.populate({
          quiz_reports: [{
            id: '1',
            report_type: 'student_analysis',
            progress: {
              id: '1',
              workflow_state: K.PROGRESS_ACTIVE,
              url: '/progress/1'
            }
          }]
        });

        this.sendAction('quizReports:generate', 'student_analysis');
        expect(this.requests.length).toBe(0);
        expect(onError).toHaveBeenCalled();
      });

      it('should reject if the report is already generated', function() {
        subject.populate({
          quiz_reports: [{
            id: '1',
            report_type: 'student_analysis',
            file: {
              url: '/attachments/1'
            }
          }]
        });

        this.sendAction('quizReports:generate', 'student_analysis');
        expect(this.requests.length).toBe(0);
        expect(onError).toHaveBeenCalled();
      });
    });
  });
});
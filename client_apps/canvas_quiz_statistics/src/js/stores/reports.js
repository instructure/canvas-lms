define(function(require) {
  var Store = require('../core/store');
  var config = require('../config');
  var K = require('../constants');
  var QuizReports = require('../collections/quiz_reports');
  var pollProgress = require('../services/poll_progress');
  var populateCollection = require('./common/populate_collection');
  var quizReports = new QuizReports();

  var triggerDownload = function(url) {
    var iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = url;
    document.body.appendChild(iframe);
  };

  var generationRequests = [];

  /**
   * @class Stores.QuizReports
   * Load and generate quiz reports.
   */
  return new Store('quizReports', {
    /**
     * Load quiz reports from the Canvas API.
     *
     * @async
     * @fires change
     * @needs_cfg quizReportsUrl
     * @needs_cfg includesAllVersions
     *
     * @return {RSVP.Promise}
     *         Fulfills when the reports have been loaded.
     */
    load: function() {
      var onLoad = this.populate.bind(this);
      var url = config.quizReportsUrl;

      if (!url) {
        return config.onError('Missing configuration parameter "quizReportsUrl".');
      }

      return quizReports.fetch({
        data: {
          include: [ 'progress', 'file' ],
          includes_all_versions: config.includesAllVersions
        }
      }).then(function(payload) {
        onLoad(payload, { replace: true, track: true });
      });
    },

    /**
     * Populate the store with pre-loaded data.
     *
     * @param {Object} payload
     *        The payload to extract the reports from. This is what you received
     *        by hitting the Canvas reports index JSON-API endpoint.
     *
     * @param {Object} [options={}]
     * @param {Boolean} [options.replace=true]
     *        Forwarded to Stores.Common#populateCollection
     *
     * @param {Boolean} [options.track=false]
     *        Pass to true if the payload may contain any reports that are
     *        currently being generated, then the store will track their
     *        generation progress.
     *
     * @fires change
     */
    populate: function(payload, options) {
      options = options || {};

      populateCollection(quizReports, payload, options.replace);

      if (options.track) {
        quizReports
          .where({ isGenerating: true })
          .forEach(this.trackReportGeneration.bind(this));
      }

      this.emitChange();
    },

    getAll: function() {
      return quizReports.toJSON();
    },

    actions: {
      generate: function(reportType, onChange, onError) {
        var quizReport = quizReports.findWhere({ reportType: reportType });

        if (quizReport) {
          if (quizReport.get('isGenerating')) {
            return onError('report is already being generated');
          }
          else if (quizReport.get('isGenerated')) {
            return onError('report is already generated');
          }
        }

        quizReports.generate(reportType).then(function(quizReport) {
          this.trackReportGeneration(quizReport, true);
          onChange();
        }.bind(this), onError);
      },

      regenerate: function(reportId, onChange, onError) {
        var quizReport = quizReports.get(reportId);
        var progress = quizReport.get('progress');

        if (!quizReport) {
          return onError('no such report');
        }
        else if (!progress) {
          return onError('report is not being generated');
        }
        else if (progress.workflowState !== K.PROGRESS_FAILED) {
          return onError('report generation is not stuck');
        }

        quizReports.generate(quizReport.get('reportType'))
          .then(function retrackGeneration(quizReport) {
            this.stopTracking(quizReport.get('id'));
            this.trackReportGeneration(quizReport, true);

            onChange();
          }.bind(this), onError);
      },

      abort: function(reportId, onChange, onError) {
        var quizReport = quizReports.get(reportId);

        if (!quizReport) {
          return onError('no such quiz report');
        }
        else if (!quizReport.get('progress')) {
          return onError('quiz report is not being generated');
        }

        quizReport.destroy({ wait: true }).then(function() {
          this.stopTracking(quizReport.get('id'));

          // destroy() would remove the report from the collection but we
          // don't want that... just reload the report from the server:
          quizReports.add(quizReport);
          quizReport.fetch().then(onChange, onError);
        }.bind(this), onError);
      }
    },

    __reset__: function() {
      quizReports.reset();
      generationRequests = [];

      return Store.prototype.__reset__.call(this);
    },

    /** @private */
    trackReportGeneration: function(quizReport, autoDownload) {
      var emitChange, progressUrl, poll, reload;
      var quizReportId = quizReport.get('id');
      var generationRequest = generationRequests.filter(function(request) {
        return request.quizReportId === quizReportId;
      })[0];

      // we're already tracking
      if (generationRequest) {
        return;
      }

      generationRequest = {
        quizReportId: quizReportId,
        autoDownload: autoDownload
      };

      generationRequests.push(generationRequest);

      emitChange = this.emitChange.bind(this);
      progressUrl = quizReport.get('progress').url;

      poll = function() {
        return pollProgress(progressUrl, {
          interval: 1000,
          onTick: function(completion, progress) {
            quizReport.set('progress', progress);
            emitChange();
          }
        });
      };

      reload = function() {
        return quizReport.fetch({
          data: {
            include: [ 'progress', 'file' ]
          }
        });
      };

      poll().then(reload, reload).finally(function() {
        this.stopTracking(quizReportId);

        if (generationRequest.autoDownload && quizReport.get('isGenerated')) {
          triggerDownload(quizReport.get('file').url);
        }

        emitChange();
      }.bind(this));
    },

    /** @private */
    stopTracking: function(quizReportId) {
      var request = generationRequests.filter(function(request) {
        return request.quizReportId === quizReportId;
      })[0];

      if (request) {
        generationRequests.splice(generationRequests.indexOf(request), 1);
      }
    }
  });
});
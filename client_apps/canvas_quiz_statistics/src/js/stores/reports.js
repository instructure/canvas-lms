define(function(require) {
  var Store = require('../core/store');
  var config = require('../config');
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
  var store = new Store('quizReports', {
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
     *
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

        if (quizReport && (quizReport.get('isGenerating') || quizReport.get('isGenerated'))) {
          return onError();
        }

        quizReports.generate(reportType).then(function(quizReport) {
          this.trackReportGeneration(quizReport, true);
          onChange();
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
      var onChange, progressUrl, poll, reload;
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

      onChange = this.emitChange.bind(this);
      progressUrl = quizReport.get('progress').url;

      poll = function() {
        return pollProgress(progressUrl, {
          interval: 1000,
          onTick: function(completion) {
            quizReport.attributes.progress.completion = completion;
            onChange();
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

      poll().finally(reload).then(function() {
        if (generationRequest.autoDownload) {
          triggerDownload(quizReport.get('file').url);
        }

        onChange();
      });
    },

  });

  return store;
});
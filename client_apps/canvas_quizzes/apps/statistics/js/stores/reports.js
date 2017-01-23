define((require) => {
  const Store = require('canvas_quizzes/core/store');
  const Dispatcher = require('../core/dispatcher');
  const config = require('../config');
  const K = require('../constants');
  const QuizReports = require('../collections/quiz_reports');
  const pollProgress = require('../services/poll_progress');
  const populateCollection = require('./common/populate_collection');
  const quizReports = new QuizReports();

  const triggerDownload = function (url) {
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = url;
    document.body.appendChild(iframe);
  };

  let generationRequests = [];

  /**
   * @class Statistics.Stores.QuizReports
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
    load () {
      const onLoad = this.populate.bind(this);
      const url = config.quizReportsUrl;

      if (!url) {
        return config.onError('Missing configuration parameter "quizReportsUrl".');
      }

      return quizReports.fetch({
        data: {
          include: ['progress', 'file'],
          includes_all_versions: config.includesAllVersions
        }
      }).then((payload) => {
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
    populate (payload, options) {
      options = options || {};

      populateCollection(quizReports, payload, options.replace);

      if (options.track) {
        quizReports
          .where({ isGenerating: true })
          .forEach(this.trackReportGeneration.bind(this));
      }

      this.emitChange();
    },

    getAll () {
      return quizReports.toJSON();
    },

    actions: {
      generate (reportType, onChange, onError) {
        const quizReport = quizReports.findWhere({ reportType });

        if (quizReport) {
          if (quizReport.get('isGenerating')) {
            return onError('report is already being generated');
          } else if (quizReport.get('isGenerated')) {
            return onError('report is already generated');
          }
        }

        quizReports.generate(reportType).then((quizReport) => {
          this.trackReportGeneration(quizReport, true);
          onChange();
        }, onError);
      },

      regenerate (reportId, onChange, onError) {
        const quizReport = quizReports.get(reportId);
        const progress = quizReport.get('progress');

        if (!quizReport) {
          return onError('no such report');
        } else if (!progress) {
          return onError('report is not being generated');
        } else if (progress.workflowState !== K.PROGRESS_FAILED) {
          return onError('report generation is not stuck');
        }

        quizReports.generate(quizReport.get('reportType'))
          .then((quizReport) => {
            this.stopTracking(quizReport.get('id'));
            this.trackReportGeneration(quizReport, true);

            onChange();
          }, onError);
      },

      abort (reportId, onChange, onError) {
        const quizReport = quizReports.get(reportId);

        if (!quizReport) {
          return onError('no such quiz report');
        } else if (!quizReport.get('progress')) {
          return onError('quiz report is not being generated');
        }

        quizReport.destroy({ wait: true }).then(() => {
          this.stopTracking(quizReport.get('id'));

          // destroy() would remove the report from the collection but we
          // don't want that... just reload the report from the server:
          quizReports.add(quizReport);
          quizReport.fetch().then(onChange, onError);
        }, onError);
      }
    },

    __reset__ () {
      quizReports.reset();
      generationRequests = [];

      return Store.prototype.__reset__.call(this);
    },

    /** @private */
    trackReportGeneration (quizReport, autoDownload) {
      let emitChange,
        progressUrl,
        poll,
        reload;
      const quizReportId = quizReport.get('id');
      let generationRequest = generationRequests.filter(request => request.quizReportId === quizReportId)[0];

      // we're already tracking
      if (generationRequest) {
        return;
      }

      generationRequest = {
        quizReportId,
        autoDownload
      };

      generationRequests.push(generationRequest);

      emitChange = this.emitChange.bind(this);
      progressUrl = quizReport.get('progress').url;

      poll = function () {
        return pollProgress(progressUrl, {
          interval: 1000,
          onTick (completion, progress) {
            quizReport.set('progress', progress);
            emitChange();
          }
        });
      };

      reload = function () {
        return quizReport.fetch({
          data: {
            include: ['progress', 'file']
          }
        });
      };

      poll().then(reload, reload).finally(() => {
        this.stopTracking(quizReportId);

        if (generationRequest.autoDownload && quizReport.get('isGenerated')) {
          triggerDownload(quizReport.get('file').url);
        }

        emitChange();
      });
    },

    /** @private */
    stopTracking (quizReportId) {
      const request = generationRequests.filter(request => request.quizReportId === quizReportId)[0];

      if (request) {
        generationRequests.splice(generationRequests.indexOf(request), 1);
      }
    }
  }, Dispatcher);
});

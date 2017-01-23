define((require) => {
  const RSVP = require('rsvp');
  const $ = require('canvas_packages/jquery');
  const CoreAdapter = require('canvas_quizzes/core/adapter');
  const K = require('../constants');
  const config = require('../config');
  const Adapter = new CoreAdapter(config);
  const pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');

  const fetchProgress = function (url) {
    return Adapter.request({
      type: 'GET',
      url,
    }).then(payload => pickAndNormalize(payload, K.PROGRESS_ATTRS));
  };

  return function pollProgress (url, options) {
    let poll,
      poller;
    const service = RSVP.defer();

    options = options || {};

    $(window).on('beforeunload.progress', () => clearTimeout(poller));

    poll = function () {
      fetchProgress(url).then((data) => {
        if (options.onTick) {
          options.onTick(data.completion, data);
        }

        if (data.workflowState === K.PROGRESS_FAILED) {
          service.reject();
        } else if (data.workflowState === K.PROGRESS_COMPLETE) {
          service.resolve();
        } else {
          poller = setTimeout(poll, options.interval || config.pollingFrequency);
        }
      }, () => {
        service.reject();
      });
    };

    poll();

    return service.promise;
  };
});

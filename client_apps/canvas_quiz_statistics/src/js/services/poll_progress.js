define(function(require) {
  var RSVP = require('rsvp');
  var $ = require('canvas_packages/jquery');
  var Adapter = require('../core/adapter');
  var K = require('../constants');
  var config = require('../config');

  var fetchProgress = function(url) {
    return Adapter.request({
      type: 'GET',
      url: url,
    }).then(function(payload) {
      return {
        completion: payload.completion,
        workflowState: payload.workflow_state,
      };
    });
  };

  return function pollProgress(url, options) {
    var poll, poller;
    var service = RSVP.defer();

    options = options || {};

    $(window).on('beforeunload.progress', function() {
      return clearTimeout(poller);
    });

    poll = function() {
      fetchProgress(url).then(function(data) {
        if (options.onTick) {
          options.onTick(data.completion, data.workflowState);
        }

        if (data.workflowState === K.PROGRESS_FAILED) {
          service.reject();
        } else if (data.workflowState === K.PROGRESS_COMPLETE) {
          service.resolve();
        } else {
          poller = setTimeout(poll, options.interval || config.pollingFrequency);
        }
      }, function() {
        service.reject();
      });
    };

    poll();

    return service.promise;
  };
});
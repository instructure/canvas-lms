define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var Event = require('../models/event');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var config = require('../config');

  return Backbone.Collection.extend({
    model: Event,

    url: function() {
      return config.eventsUrl;
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_submission_events');
    }
  });
});
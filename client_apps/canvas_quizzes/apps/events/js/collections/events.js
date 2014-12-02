define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var Event = require('../models/event');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var config = require('../config');
  var PaginatedCollection = require('../mixins/paginated_collection');

  return Backbone.Collection.extend({
    model: Event,
    constructor: function() {
      PaginatedCollection(this);
      return Backbone.Collection.apply(this, arguments);
    },

    url: function() {
      return config.eventsUrl;
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_submission_events');
    }
  });
});
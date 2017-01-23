define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const Event = require('../models/event');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const config = require('../config');
  const PaginatedCollection = require('../mixins/paginated_collection');

  return Backbone.Collection.extend({
    model: Event,
    constructor () {
      PaginatedCollection(this);
      return Backbone.Collection.apply(this, arguments);
    },

    url () {
      return config.eventsUrl;
    },

    parse (payload) {
      return fromJSONAPI(payload, 'quiz_submission_events');
    }
  });
});

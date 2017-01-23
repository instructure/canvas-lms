define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const Question = require('../models/question');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const config = require('../config');
  const PaginatedCollection = require('../mixins/paginated_collection');

  return Backbone.Collection.extend({
    model: Question,
    constructor () {
      PaginatedCollection(this);
      return Backbone.Collection.apply(this, arguments);
    },

    url () {
      return config.questionsUrl;
    },

    parse (payload) {
      return fromJSONAPI(payload, 'quiz_questions');
    }
  });
});

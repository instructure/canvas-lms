define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var Question = require('../models/question');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var config = require('../config');
  var PaginatedCollection = require('../mixins/paginated_collection');

  return Backbone.Collection.extend({
    model: Question,
    constructor: function() {
      PaginatedCollection(this);
      return Backbone.Collection.apply(this, arguments);
    },

    url: function() {
      return config.questionsUrl;
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_questions');
    }
  });
});
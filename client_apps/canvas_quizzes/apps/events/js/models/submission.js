define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var K = require('../constants');
  var config = require('../config');

  return Backbone.Model.extend({
    url: function() {
      return config.submissionUrl;
    },

    parse: function(payload) {
      var attrs;

      attrs = fromJSONAPI(payload, 'quiz_submissions', true);
      attrs = pickAndNormalize(attrs, K.SUBMISSION_ATTRS);

      return attrs;
    }
  });
});
define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var K = require('../constants');

  return Backbone.Model.extend({
    parse: function(payload) {
      var attrs;

      attrs = fromJSONAPI(payload, 'quiz_submission_events', true);
      attrs = pickAndNormalize(attrs, K.EVENT_ATTRS);
      attrs.type = attrs.eventType;
      attrs.data = attrs.eventData;

      delete attrs.eventType;
      delete attrs.eventData;

      if (attrs.type === K.EVT_QUESTION_ANSWERED) {
        attrs.data = attrs.data.map(function(record) {
          return pickAndNormalize(record, K.EVENT_DATA_ATTRS);
        });
      }

      if (attrs.type === K.EVT_PAGE_BLURRED) {
        attrs.flag = K.EVT_FLAG_WARNING;
      }
      else if (attrs.type === K.EVT_PAGE_FOCUSED) {
        attrs.flag = K.EVT_FLAG_OK;
      }

      return attrs;
    }
  });
});
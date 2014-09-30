define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var QuizReport = require('../models/quiz_report');
  var fromJSONAPI = require('../models/common/from_jsonapi');
  var config = require('../config');
  var Adapter = require('../core/adapter');

  return Backbone.Collection.extend({
    model: QuizReport,

    url: function() {
      return config.quizReportsUrl;
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_reports');
    },

    generate: function(reportType) {
      return Adapter.request({
        type: 'POST',
        url: this.url(),
        data: {
          quiz_reports: [{
            report_type: reportType,
            includes_all_versions: config.includesAllVersions
          }],
          include: ['progress', 'file']
        }
      }).then(function(payload) {
        var quizReports = this.add(payload, { parse: true, merge: true });
        return quizReports[0];
      }.bind(this));
    }
  });
});
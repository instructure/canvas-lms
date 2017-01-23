define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const QuizReport = require('../models/quiz_report');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const config = require('../config');
  const CoreAdapter = require('canvas_quizzes/core/adapter');
  const Adapter = new CoreAdapter(config);
  const SORT_ORDER = [
    'student_analysis',
    'item_analysis'
  ];

  return Backbone.Collection.extend({
    model: QuizReport,

    url () {
      return config.quizReportsUrl;
    },

    parse (payload) {
      return fromJSONAPI(payload, 'quiz_reports');
    },

    generate (reportType) {
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
      }).then((payload) => {
        const quizReports = this.add(payload, { parse: true, merge: true });
        return quizReports[0];
      });
    },

    comparator (model) {
      return SORT_ORDER.indexOf(model.get('reportType'));
    }
  });
});

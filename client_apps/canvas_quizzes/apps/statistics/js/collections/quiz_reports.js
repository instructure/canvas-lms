/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define(function(require) {
  var Backbone = require('canvas_packages/backbone')
  var QuizReport = require('../models/quiz_report')
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi')
  var config = require('../config')
  var CoreAdapter = require('canvas_quizzes/core/adapter')
  var Adapter = new CoreAdapter(config)
  var SORT_ORDER = ['student_analysis', 'item_analysis']

  return Backbone.Collection.extend({
    model: QuizReport,

    url: function() {
      return config.quizReportsUrl
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_reports')
    },

    generate: function(reportType) {
      return Adapter.request({
        type: 'POST',
        url: this.url(),
        data: {
          quiz_reports: [
            {
              report_type: reportType,
              includes_all_versions: config.includesAllVersions
            }
          ],
          include: ['progress', 'file']
        }
      }).then(
        function(payload) {
          var quizReports = this.add(payload, {parse: true, merge: true})
          return quizReports[0]
        }.bind(this)
      )
    },

    comparator: function(model) {
      return SORT_ORDER.indexOf(model.get('reportType'))
    }
  })
})

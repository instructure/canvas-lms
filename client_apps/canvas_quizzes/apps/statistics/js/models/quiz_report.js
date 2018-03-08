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
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize')
  var K = require('../constants')
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi')
  var isGenerating = function(report) {
    var workflowState = report.progress.workflowState
    return ['queued', 'running'].indexOf(workflowState) > -1
  }

  return Backbone.Model.extend({
    parse: function(payload) {
      var attrs

      payload = fromJSONAPI(payload, 'quiz_reports', true)
      attrs = pickAndNormalize(payload, K.QUIZ_REPORT_ATTRS)

      attrs.progress = pickAndNormalize(payload.progress, K.PROGRESS_ATTRS)
      attrs.file = pickAndNormalize(payload.file, K.ATTACHMENT_ATTRS)
      attrs.isGenerated = !!(attrs.file && attrs.file.url)
      attrs.isGenerating = !attrs.isGenerated && !!(attrs.progress && isGenerating(attrs))

      return attrs
    }
  })
})

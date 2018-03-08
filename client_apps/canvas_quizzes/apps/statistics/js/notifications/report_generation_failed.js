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
  var QuizReports = require('../stores/reports')
  var Notification = require('canvas_quizzes/models/notification')
  var K = require('../constants')

  // Notify the teacher of failures during CSV report generation.
  var watchForReportGenerationFailures = function() {
    return QuizReports.getAll()
      .filter(function(report) {
        if (!!report.progress) {
          return report.progress.workflowState === K.PROGRESS_FAILED
        }
      })
      .map(function(report) {
        return new Notification({
          id: ['reports', report.id, report.progress.id].join('_'),
          code: K.NOTIFICATION_REPORT_GENERATION_FAILED,
          context: {
            reportId: report.id,
            reportType: report.reportType
          }
        })
      })
  }

  watchForReportGenerationFailures.watchTargets = [QuizReports]

  return watchForReportGenerationFailures
})

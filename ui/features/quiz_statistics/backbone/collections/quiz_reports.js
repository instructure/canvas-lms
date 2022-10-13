/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import config from '../../config'
import CoreAdapter from '@canvas/quiz-legacy-client-apps/adapter'
import fromJSONAPI from '@canvas/quiz-legacy-client-apps/util/from_jsonapi'
import QuizReport from '../models/quiz_report'

const Adapter = new CoreAdapter(config)
const SORT_ORDER = ['student_analysis', 'item_analysis']

export default Backbone.Collection.extend({
  model: QuizReport,

  url() {
    return config.quizReportsUrl
  },

  parse(payload) {
    return fromJSONAPI(payload, 'quiz_reports')
  },

  generate(reportType) {
    return Adapter.request({
      type: 'POST',
      url: this.url(),
      data: {
        quiz_reports: [
          {
            report_type: reportType,
            includes_all_versions: config.includesAllVersions,
          },
        ],
        include: ['progress', 'file'],
      },
    }).then(
      function (payload) {
        const quizReports = this.add(payload, {parse: true, merge: true})
        return quizReports[0]
      }.bind(this)
    )
  },

  comparator(model) {
    return SORT_ORDER.indexOf(model.get('reportType'))
  },
})

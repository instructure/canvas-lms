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

import Backbone from 'backbone'
import fromJSONAPI from '../../shared/models/common/from_jsonapi'
import K from '../constants'
import pickAndNormalize from '../../shared/models/common/pick_and_normalize'

const isGenerating = function(report) {
  const workflowState = report.progress.workflowState
  return ['queued', 'running'].indexOf(workflowState) > -1
}

export default Backbone.Model.extend({
  parse(payload) {
    let attrs

    payload = fromJSONAPI(payload, 'quiz_reports', true)
    attrs = pickAndNormalize(payload, K.QUIZ_REPORT_ATTRS)

    attrs.progress = pickAndNormalize(payload.progress, K.PROGRESS_ATTRS)
    attrs.file = pickAndNormalize(payload.file, K.ATTACHMENT_ATTRS)
    attrs.isGenerated = !!(attrs.file && attrs.file.url)
    attrs.isGenerating = !attrs.isGenerated && !!(attrs.progress && isGenerating(attrs))

    return attrs
  }
})

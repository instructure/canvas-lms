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
import pickAndNormalize from '@canvas/quiz-legacy-client-apps/util/pick_and_normalize'
import fromJSONAPI from '@canvas/quiz-legacy-client-apps/util/from_jsonapi'
import K from '../../constants'

const QuizSubmissionEvent = Backbone.Model.extend({
  parse(payload) {
    let attrs

    attrs = fromJSONAPI(payload, 'quiz_submission_events', true)
    attrs = pickAndNormalize(attrs, K.EVENT_ATTRS)
    attrs.type = attrs.eventType
    attrs.data = attrs.eventData

    delete attrs.eventType
    delete attrs.eventData

    if (attrs.type === K.EVT_QUESTION_ANSWERED) {
      attrs.data = attrs.data.map(function (record) {
        return pickAndNormalize(record, K.EVENT_DATA_ATTRS)
      })
    }

    if (attrs.type === K.EVT_PAGE_BLURRED) {
      attrs.flag = K.EVT_FLAG_WARNING
    } else if (attrs.type === K.EVT_PAGE_FOCUSED) {
      attrs.flag = K.EVT_FLAG_OK
    }

    return attrs
  },
})

export default QuizSubmissionEvent

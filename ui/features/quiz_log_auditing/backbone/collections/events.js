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
import Event from '../models/event'
import fromJSONAPI from '@canvas/quiz-legacy-client-apps/util/from_jsonapi'
import config from '../../config'
import PaginatedCollection from '../mixins/paginated_collection'

export default Backbone.Collection.extend({
  model: Event,
  // eslint-disable-next-line object-shorthand
  constructor: function () {
    PaginatedCollection(this)
    return Backbone.Collection.apply(this, arguments)
  },

  url() {
    return config.eventsUrl
  },

  parse(payload) {
    return fromJSONAPI(payload, 'quiz_submission_events')
  },
})

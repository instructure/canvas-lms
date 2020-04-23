/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {asJson, consumePrefetchedXHR} from '@instructure/js-utils'

export default class GradingPeriodAssignmentsLoader {
  constructor({dispatch, gradebook}) {
    this._dispatch = dispatch
    this._gradebook = gradebook
  }

  loadGradingPeriodAssignments() {
    let promise

    /*
     * When user ids have been prefetched, the data is only known valid for the
     * first request. Consume it by pulling it out of the prefetch store, which
     * will force all subsequent requests for user ids to call through the
     * network.
     */
    promise = consumePrefetchedXHR('grading_period_assignments')
    if (promise) {
      promise = asJson(promise)
    } else {
      const courseId = this._gradebook.course.id
      const url = `/courses/${courseId}/gradebook/grading_period_assignments`
      promise = this._dispatch.getJSON(url)
    }

    return promise.then(data => {
      this._gradebook.updateGradingPeriodAssignments(data.grading_period_assignments)
    })
  }
}

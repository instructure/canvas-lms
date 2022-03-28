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

import moment from 'moment-timezone'
import {BlackoutDate} from '../shared/types'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import doFetchApi from '@canvas/do-fetch-api-effect'

/* API methods */

export const sync = (blackoutDates: BlackoutDate[], course_id: string | number) => {
  const path = course_id
    ? `/api/v1/courses/${course_id}/blackout_dates`
    : '/api/v1/acccounts/???/blackout_dates' // this hasn't been worked out yet.

  return doFetchApi<ApiFormattedBlackoutDate[]>({
    path,
    method: 'PUT',
    body: {
      blackout_dates: blackoutDates.map(
        (bd: BlackoutDate): ApiFormattedBlackoutDate => transformBlackoutDateForApi(bd)
      )
    }
  })
    .then(result => {
      if (!result.response.ok) {
        throw new Error(result.response.statusText)
      }
      return result
    })
    .then(result => {
      return ((result.json || []) as Array<ApiFormattedBlackoutDate>).map(bd =>
        transformBlackoutDateFromApi(bd)
      )
    })
}

/* API transformers */
interface ApiFormattedBlackoutDate {
  event_title: string
  start_date: string
  end_date: string
}

function transformBlackoutDateForApi(blackoutDate: BlackoutDate): ApiFormattedBlackoutDate {
  const formattedBlackoutDate: ApiFormattedBlackoutDate = {
    event_title: blackoutDate.event_title,
    start_date: DateHelpers.formatDate(blackoutDate.start_date),
    end_date: DateHelpers.formatDate(blackoutDate.end_date)
  }
  return formattedBlackoutDate
}

function transformBlackoutDateFromApi(response: ApiFormattedBlackoutDate): BlackoutDate {
  const transformedBlackoutDate: BlackoutDate = {
    ...response,
    start_date: moment(response.start_date),
    end_date: moment(response.end_date)
  }
  return transformedBlackoutDate
}

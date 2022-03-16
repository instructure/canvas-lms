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

import {BlackoutDate} from '../shared/types'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import doFetchApi from '@canvas/do-fetch-api-effect'

/* API methods */

export const create = (blackoutDate: BlackoutDate) =>
  doFetchApi<{blackout_date: BlackoutDate}>({
    path: '/api/v1/blackout_dates',
    method: 'POST',
    body: transformBlackoutDateForApi(blackoutDate)
  }).then(({json}) => json?.blackout_date)

export const deleteBlackoutDate = async (id: number | string) =>
  (await doFetchApi({path: `/api/v1/blackout_dates/${id}`, method: 'DELETE'})).json

/* API transformers */

interface ApiFormattedBlackoutDate {
  course_id?: number | string
  event_title: string
  start_date: string
  end_date: string
  admin_level: boolean
}

const transformBlackoutDateForApi = (blackoutDate: BlackoutDate): ApiFormattedBlackoutDate => {
  const formattedBlackoutDate: ApiFormattedBlackoutDate = {
    event_title: blackoutDate.event_title,
    start_date: DateHelpers.formatDate(blackoutDate.start_date),
    end_date: DateHelpers.formatDate(blackoutDate.end_date),
    admin_level: !!blackoutDate.admin_level
  }

  if (blackoutDate.course_id) {
    formattedBlackoutDate.course_id = blackoutDate.course_id
  }

  return formattedBlackoutDate
}

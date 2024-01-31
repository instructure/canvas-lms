// @ts-nocheck
//
// Copyright (C) 2016 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import axios from '@canvas/axios'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import replaceTags from '@canvas/util/replaceTags'
import type {CamelizedGradingPeriod, SerializedGradingPeriod} from '../grading.d'

const batchUpdateUrl = (id: string) => replaceTags(ENV.GRADING_PERIODS_UPDATE_URL, 'set_id', id)

const serializePeriods = (periods?: CamelizedGradingPeriod[]) => {
  const serialized = (periods || []).map(period => ({
    id: period.id,
    title: period.title,
    start_date: period.startDate,
    end_date: period.endDate,
    close_date: period.closeDate,
    weight: period.weight,
  }))
  return {grading_periods: serialized}
}

export default {
  deserializePeriods(periods?: SerializedGradingPeriod[]): CamelizedGradingPeriod[] {
    return (periods || []).map(period => ({
      id: period.id,
      title: period.title,
      startDate: new Date(period.start_date),
      endDate: new Date(period.end_date),
      closeDate: new Date(period.close_date),
      isLast: Boolean(period.is_last),
      isClosed: Boolean(period.is_closed),
      weight: period.weight,
    }))
  },

  batchUpdate(setId: string, periods: CamelizedGradingPeriod[]) {
    return new Promise((resolve, reject) =>
      axios
        .patch<{
          grading_periods: SerializedGradingPeriod[]
        }>(batchUpdateUrl(setId), serializePeriods(periods))
        .then(response => resolve(this.deserializePeriods(response.data.grading_periods)))
        .catch(error => reject(error))
    )
  },
}

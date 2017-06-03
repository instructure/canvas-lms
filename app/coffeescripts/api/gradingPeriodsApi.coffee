#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'axios'
  'jquery.instructure_misc_helpers'
], ($, _, axios) ->
  batchUpdateUrl = (id) =>
    $.replaceTags(ENV.GRADING_PERIODS_UPDATE_URL, 'set_id', id)

  serializePeriods = (periods) ->
    serialized = _.map periods, (period) ->
      {
        id: period.id
        title: period.title
        start_date: period.startDate
        end_date: period.endDate
        close_date: period.closeDate
        weight: period.weight
      }
    grading_periods: serialized

  deserializePeriods: (periods) ->
    _.map periods, (period) ->
      {
        id: period.id
        title: period.title
        startDate: new Date(period.start_date)
        endDate: new Date(period.end_date)
        closeDate: new Date(period.close_date)
        isLast: period.is_last
        isClosed: period.is_closed
        weight: period.weight
      }

  batchUpdate: (setId, periods) ->
    promise = new Promise (resolve, reject) =>
      axios.patch(batchUpdateUrl(setId), serializePeriods(periods))
           .then (response) =>
             resolve(@deserializePeriods(response.data.grading_periods))
           .catch (error) ->
             reject(error)
    promise

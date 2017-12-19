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

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!grading_periods'
import DateHelper from 'jsx/shared/helpers/dateHelper'
import gradingPeriodsApi from './gradingPeriodsApi'
import axios from 'axios'
import Depaginate from 'jsx/shared/CheatDepaginator'
import 'jquery.instructure_misc_helpers'

const listUrl = () => ENV.GRADING_PERIOD_SETS_URL

const createUrl = () => ENV.GRADING_PERIOD_SETS_URL

const updateUrl = id => $.replaceTags(ENV.GRADING_PERIOD_SET_UPDATE_URL, 'id', id)

const serializeSet = (set) => {
  const gradingPeriodSetAttrs = {
    title: set.title,
    weighted: set.weighted,
    display_totals_for_all_grading_periods: set.displayTotalsForAllGradingPeriods
  }
  return {
    grading_period_set: gradingPeriodSetAttrs,
    enrollment_term_ids: set.enrollmentTermIDs
  }
}

const baseDeserializeSet = set => ({
  id: set.id.toString(),
  title: gradingPeriodSetTitle(set),
  weighted: !!set.weighted,
  displayTotalsForAllGradingPeriods: set.display_totals_for_all_grading_periods,
  gradingPeriods: gradingPeriodsApi.deserializePeriods(set.grading_periods),
  permissions: set.permissions,
  createdAt: new Date(set.created_at)
})

const gradingPeriodSetTitle = (set) => {
  if (set.title && set.title.trim()) {
    return set.title.trim()
  } else {
    const createdAt = DateHelper.formatDateForDisplay(new Date(set.created_at))
    return I18n.t('Set created %{createdAt}', {createdAt})
  }
}

const deserializeSet = function (set) {
  const newSet = baseDeserializeSet(set)
  newSet.enrollmentTermIDs = set.enrollment_term_ids
  return newSet
}

const deserializeSets = setGroups =>
  _.flatten(_.map(setGroups, group =>
    _.map(group.grading_period_sets, set => baseDeserializeSet(set))
  )
)

export default {
  deserializeSet,

  list () {
    return new Promise((resolve, reject) =>
      Depaginate(listUrl())
        .then(response => resolve(deserializeSets(response)))
        .fail(error => reject(error))
    )
  },

  create (set) {
    return axios.post(createUrl(), serializeSet(set))
                .then(response => deserializeSet(response.data.grading_period_set))
  },

  update (set) {
    return axios.patch(updateUrl(set.id), serializeSet(set))
                .then(response => set)
  }
}

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
import {useScope as useI18nScope} from '@canvas/i18n'
import DateHelper from '@canvas/datetime/dateHelper'
import NaiveRequestDispatch from '@canvas/network/NaiveRequestDispatch/index'
import gradingPeriodsApi from './gradingPeriodsApi'
import type {CamelizedGradingPeriodSet} from '../grading.d'
import type {GradingPeriodSet, GradingPeriodSetGroup} from 'api.d'
import {EnvGradingStandardsCommon} from '@canvas/global/env/EnvGradingStandards'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import replaceTags from '@canvas/util/replaceTags'

// Allow unchecked access to ENV variables that should exist in this context
declare const ENV: GlobalEnv & EnvGradingStandardsCommon

const I18n = useI18nScope('gradingPeriodSetsApi')

const listUrl = () => ENV.GRADING_PERIOD_SETS_URL

const createUrl = () => ENV.GRADING_PERIOD_SETS_URL

const updateUrl = id => replaceTags(ENV.GRADING_PERIOD_SET_UPDATE_URL, 'id', id)

const serializeSet = (set: CamelizedGradingPeriodSet) => {
  const gradingPeriodSetAttrs = {
    title: set.title,
    weighted: set.weighted,
    display_totals_for_all_grading_periods: set.displayTotalsForAllGradingPeriods,
  }
  return {
    grading_period_set: gradingPeriodSetAttrs,
    enrollment_term_ids: set.enrollmentTermIDs,
  }
}

const baseDeserializeSet = (set: GradingPeriodSet): CamelizedGradingPeriodSet => ({
  id: set.id.toString(),
  title: gradingPeriodSetTitle(set),
  weighted: !!set.weighted,
  displayTotalsForAllGradingPeriods: set.display_totals_for_all_grading_periods,
  gradingPeriods: gradingPeriodsApi.deserializePeriods(set.grading_periods),
  permissions: set.permissions,
  createdAt: new Date(set.created_at),
  enrollmentTermIDs: undefined,
})

const gradingPeriodSetTitle = set => {
  if (set.title && set.title.trim()) {
    return set.title.trim()
  } else {
    const createdAt = DateHelper.formatDateForDisplay(new Date(set.created_at))
    return I18n.t('Set created %{createdAt}', {createdAt})
  }
}

const deserializeSet = function (set: GradingPeriodSet): CamelizedGradingPeriodSet {
  const newSet = baseDeserializeSet(set)
  newSet.enrollmentTermIDs = set.enrollment_term_ids
  return newSet
}

const deserializeSets = (setGroups: GradingPeriodSetGroup[]): CamelizedGradingPeriodSet[] =>
  setGroups.flatMap(group => group.grading_period_sets.map(set => baseDeserializeSet(set)))

export default {
  deserializeSet,

  list() {
    return new Promise((resolve, reject) => {
      const dispatch = new NaiveRequestDispatch()
      /* eslint-disable promise/catch-or-return */
      dispatch
        .getDepaginated(listUrl())
        .then(response => resolve(deserializeSets(response)))
        .fail(error => reject(error))
      /* eslint-enable promise/catch-or-return */
    })
  },

  create(set) {
    return axios
      .post(createUrl(), serializeSet(set))
      .then(response => deserializeSet(response.data.grading_period_set))
  },

  update(set) {
    return axios.patch(updateUrl(set.id), serializeSet(set)).then(_response => set)
  },
}

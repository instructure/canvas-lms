/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {useMatch} from 'react-router-dom'
import GradingPeriodSetCollection from '../components/grading_period/GradingPeriodSetCollection'

export function Component() {
  const pathMatch = useMatch('/accounts/:accountId/*')
  if (!pathMatch || !pathMatch.params || !pathMatch.params.accountId) {
    throw new Error('account id is not present on path')
  }
  const accountId = pathMatch.params.accountId
  const rootAccountId = ENV.DOMAIN_ROOT_ACCOUNT_ID

  // Note: these env vars are required downstream in api callers used by the grading periods management page,
  // in addition to being required to be passed in to this component itself as props
  ENV.ENROLLMENT_TERMS_URL = `/api/v1/accounts/${rootAccountId}/terms`
  ENV.GRADING_PERIOD_SETS_URL = `/api/v1/accounts/${accountId}/grading_period_sets`
  ENV.GRADING_PERIOD_SET_UPDATE_URL = `/api/v1/accounts/${accountId}/grading_period_sets/{{id}}`
  ENV.GRADING_PERIODS_UPDATE_URL = `/api/v1/grading_period_sets/{{set_id}}/grading_periods/batch_update`
  const urls = {
    enrollmentTermsURL: ENV.ENROLLMENT_TERMS_URL,
    gradingPeriodsUpdateURL: ENV.GRADING_PERIODS_UPDATE_URL,
    gradingPeriodSetsURL: ENV.GRADING_PERIOD_SETS_URL,
    deleteGradingPeriodURL: `/api/v1/accounts/${accountId}/grading_periods/{{id}}`,
  }
  useEffect(() => {
    document.title = 'Account Grading Periods'
  }, [])

  return <GradingPeriodSetCollection readOnly={false} urls={urls} />
}

/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import AccountTabContainer from '../grading/AccountTabContainer'

ReactDOM.render(
  <AccountTabContainer
    {...{
      readOnly: ENV.GRADING_PERIODS_READ_ONLY,
      urls: {
        enrollmentTermsURL: ENV.ENROLLMENT_TERMS_URL,
        gradingPeriodsUpdateURL: ENV.GRADING_PERIODS_UPDATE_URL,
        gradingPeriodSetsURL: ENV.GRADING_PERIOD_SETS_URL,
        deleteGradingPeriodURL: ENV.DELETE_GRADING_PERIOD_URL
      }
    }}
  />,
  document.getElementById('react_grading_tabs')
)

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

import React from 'react'
import {Navigate} from 'react-router-dom'
import {TabLayout} from '../pages/TabLayout'
import {AccountGradingSchemes} from '../pages/AccountGradingSchemes'
import {AccountGradingPeriods} from '../pages/AccountGradingPeriods'
import {AccountGradingStatuses} from '../pages/AccountGradingStatuses'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

declare const ENV: GlobalEnv & {
  IS_ROOT_ACCOUNT: boolean
  ROOT_ACCOUNT_ID: string
}

export const accountGradingSettingsRoutes = [
  {
    path: 'grading_settings',
    element: <TabLayout />,
    children: [
      {path: '', element: <Navigate to="schemes" replace={true} />},
      {path: 'periods', element: <AccountGradingPeriods />},
      {path: 'schemes', element: <AccountGradingSchemes />},
      {
        path: 'statuses',
        element: (
          <AccountGradingStatuses
            isRootAccount={ENV.IS_ROOT_ACCOUNT}
            rootAccountId={ENV.ROOT_ACCOUNT_ID}
            isExtendedStatusEnabled={ENV.FEATURES.extended_submission_state}
          />
        ),
      },
    ],
  },
]

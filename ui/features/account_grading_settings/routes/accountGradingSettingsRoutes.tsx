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
import {Navigate, Route} from 'react-router-dom'

const AccountGradingSettingsRoutes = (
  <Route path="/accounts/:accountId/grading_settings" lazy={() => import('../pages/TabLayout')}>
    <Route path="" element={<Navigate to="schemes" replace={true} />} />
    <Route path="periods" lazy={() => import('../pages/AccountGradingPeriods')} />
    <Route path="schemes" lazy={() => import('../pages/AccountGradingSchemes')} />
    <Route path="statuses" lazy={() => import('../pages/AccountGradingStatuses')} />
  </Route>
)

export default AccountGradingSettingsRoutes

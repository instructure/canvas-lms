/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import AlertList from './AlertList'
import {calculateUIMetadata} from './utils'

// This is the directly-renderable Alert List that goes into the
// account settings and course settings page portals launched by
// React Router.
export default function AlertListPortal(): JSX.Element | null {
  const contextType = ENV.current_context?.type
  const alerts = ENV.ALERTS?.data
  const accountRoles = ENV.ALERTS?.account_roles ?? []

  if (!contextType || !alerts) return null

  const uiMetadata = calculateUIMetadata(accountRoles)
  const contextId = contextType === 'Course' ? ENV.COURSE_ID! : ENV.ACCOUNT_ID!
  return (
    <AlertList
      alerts={alerts}
      contextType={contextType}
      contextId={contextId}
      uiMetadata={uiMetadata}
    />
  )
}

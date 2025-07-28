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
import {useParams} from 'react-router-dom'
import {Portal} from '@instructure/ui-portal'
import FeatureFlags from '@canvas/feature-flags'
import AlertList, {calculateUIMetadata} from '@canvas/student-alerts/react/AlertList'

type PortalMount = {
  mountPoint: HTMLElement
  component: JSX.Element
}

// This is set up so it can be used to render multiple portals across the
// entire settings page settings page React code! Just repeat the pattern
// for each tab or bundle you want to render.

// Feature Flags tab
function featureFlagsTab(portals: PortalMount[]): void {
  const mountPoint = document.getElementById('tab-features-mount')
  if (!mountPoint) return
  portals.push({
    mountPoint,
    component: <FeatureFlags disableDefaults={undefined} hiddenFlags={undefined} />,
  })
}

// Alerts tab
function alertsTab(portals: PortalMount[], courseId?: string): void {
  const mountPoint = document.getElementById('alerts_mount_point')
  if (!mountPoint || !courseId) return

  const alerts = ENV.ALERTS?.data
  if (typeof alerts === 'undefined') return
  const accountRoles = ENV.ALERTS?.account_roles ?? []
  const uiMetadata = calculateUIMetadata(accountRoles)

  portals.push({
    mountPoint,
    component: (
      <AlertList
        alerts={alerts}
        contextType="Course"
        contextId={courseId}
        uiMetadata={uiMetadata}
      />
    ),
  })
}

export function Component(): JSX.Element | null {
  const params = useParams()
  const portals: Array<PortalMount> = []

  featureFlagsTab(portals)
  alertsTab(portals, params.courseId)

  return (
    <>
      {portals.map(({mountPoint, component}) => (
        <Portal key={mountPoint.id} open={true} mountNode={mountPoint}>
          {component}
        </Portal>
      ))}
    </>
  )
}

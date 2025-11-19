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

import ReactDOM from 'react-dom/client'
import ready from '../../../../packages/ready'

import AccessibilityCheckerDrawer from './react/components/AccessibilityCheckerDrawer/AccessibilityCheckerDrawer'

ready(() => {
  const drawerLayoutMountPoint = document.getElementById('a11y-checker-drawer-layout-mount-point')
  const topNavToolsDrawerLayoutMountPoint = document.getElementById('drawer-layout-mount-point')
  const canvasApplicationBody = document.getElementById('application')
  const container = document.getElementById('accessibility-checker-container')

  if (!drawerLayoutMountPoint || !canvasApplicationBody || !container) {
    return
  }

  const courseId = window.ENV.current_context?.id
  if (!courseId) {
    return
  }

  const scanDisabled = !!window.ENV.SCAN_DISABLED

  // Hides the old React root container from ui/features/top_navigation_tools/index.tsx
  if (topNavToolsDrawerLayoutMountPoint) {
    topNavToolsDrawerLayoutMountPoint.style.display = 'none'
  }

  const root = ReactDOM.createRoot(drawerLayoutMountPoint)
  root.render(
    <AccessibilityCheckerDrawer
      pageContent={canvasApplicationBody}
      container={container}
      courseId={courseId}
      scanDisabled={scanDisabled}
    />,
  )
})

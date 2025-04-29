/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {createRoot} from 'react-dom/client'
import {Main} from './react/Main'
import {initAccountSelectModal} from './react/HorizonModal/InitHorizonModal'
import {LoadTab} from '../../shared/tabs/react/LoadTab'

let careersTabRoot: ReturnType<typeof createRoot> | null = null

function loadCareersTab(targetId: string) {
  if (targetId !== 'tab-canvas-career-selected') return

  const app = (
    <Main
      isHorizonAccount={window.ENV?.HORIZON_ACCOUNT || false}
      hasCourses={window.ENV?.has_courses || false}
      accountId={window.ENV?.ACCOUNT_ID || ''}
      horizonAccountLocked={window.ENV?.horizon_account_locked || false}
    />
  )

  const mountPoint = document.getElementById('tab-canvas-career-mount')
  if (!mountPoint) return

  if (!careersTabRoot) {
    careersTabRoot = createRoot(mountPoint)
  }

  careersTabRoot.render(app)

  initAccountSelectModal()
}

LoadTab(loadCareersTab)

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ready from '@instructure/ready'
import type {Role} from './react/tour'

const Tour = React.lazy(() => import('./react/tour'))

ready(() => {
  const current_roles = window.ENV.current_user_roles || []
  const current_types = window.ENV.current_user_types || []
  const roles: Role[] = []

  // Decide which tour to show based on the role
  if (current_types.includes('AccountAdmin')) {
    roles.push('admin')
  }
  if (current_roles.includes('teacher') || window.ENV.COURSE?.is_instructor) {
    roles.push('teacher')
  }
  if (current_roles.includes('student') || window.ENV.COURSE?.is_student) {
    roles.push('student')
  }
  const globalNavTourContainer = document.getElementById('global_nav_tour')

  // If the user doesn't have a role with a tour
  // don't even mount it. This saves us from having
  // to download the code-split bundle.
  if (globalNavTourContainer && roles.length > 0) {
    ReactDOM.render(
      <React.Suspense fallback={null}>
        <Tour roles={roles} />
      </React.Suspense>,
      globalNavTourContainer
    )
  }
})

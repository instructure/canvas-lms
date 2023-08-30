/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import K5Dashboard from './react/K5Dashboard'
import {useK5Theme} from '@canvas/k5/react/k5-theme'
import ready from '@instructure/ready'

useK5Theme()

ready(() => {
  const dashboardContainer = document.getElementById('dashboard-app-container')
  if (dashboardContainer) {
    ReactDOM.render(
      <K5Dashboard
        currentUser={ENV.current_user}
        currentUserRoles={ENV.current_user_roles}
        plannerEnabled={ENV.STUDENT_PLANNER_ENABLED}
        timeZone={ENV.TIMEZONE}
        hideGradesTabForStudents={ENV.HIDE_K5_DASHBOARD_GRADES_TAB}
        createPermission={ENV.CREATE_COURSES_PERMISSIONS.PERMISSION}
        restrictCourseCreation={ENV.CREATE_COURSES_PERMISSIONS.RESTRICT_TO_MCC_ACCOUNT}
        selectedContextCodes={ENV.SELECTED_CONTEXT_CODES}
        selectedContextsLimit={ENV.SELECTED_CONTEXTS_LIMIT}
        observedUsersList={ENV.OBSERVED_USERS_LIST}
        canAddObservee={ENV.CAN_ADD_OBSERVEE}
        openTodosInNewTab={ENV.OPEN_TEACHER_TODOS_IN_NEW_TAB}
        accountCalendarContexts={ENV.ACCOUNT_CALENDAR_CONTEXTS}
      />,
      dashboardContainer
    )
  }
})

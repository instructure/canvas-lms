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
import K5Course from './react/K5Course'
import k5Theme from '@canvas/k5/react/k5-theme'
import ready from '@instructure/ready'

k5Theme.use()

ready(() => {
  const courseContainer = document.getElementById('course-dashboard-container')
  if (courseContainer) {
    ReactDOM.render(
      <K5Course
        currentUser={ENV.current_user}
        name={ENV.COURSE.name}
        imageUrl={ENV.COURSE.image_url}
        plannerEnabled={ENV.STUDENT_PLANNER_ENABLED}
        timeZone={ENV.TIMEZONE}
      />,
      courseContainer
    )
  }
})

/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ModerationApp from '../assignments/ModerationApp'
import configureStore from '../assignments/store/configureStore'
import '../context_cards/StudentContextCardTrigger'

const store = configureStore({
  studentList: {
    selectedCount: 0,
    students: [],
    sort: {
      direction: 'asc',
      column: 'student_name'
    }
  },
  inflightAction: {
    review: false,
    publish: false
  },
  assignment: {
    published: window.ENV.GRADES_PUBLISHED,
    title: window.ENV.ASSIGNMENT_TITLE,
    course_id: window.ENV.COURSE_ID,
  },
  flashMessage: {
    error: false,
    message: '',
    time: Date.now()
  },
  urls: window.ENV.URLS,
})

const permissions = {
  viewGrades: window.ENV.PERMISSIONS.view_grades,
  editGrades: window.ENV.PERMISSIONS.edit_grades,
}

ReactDOM.render(<ModerationApp {...{store, permissions}} />, $('#assignment_moderation')[0])

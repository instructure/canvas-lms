import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ModerationApp from 'jsx/assignments/ModerationApp'
import configureStore from 'jsx/assignments/store/configureStore'
import 'jsx/context_cards/StudentContextCardTrigger'

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

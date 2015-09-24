require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/store/configureStore'
], ($, React, ModerationApp, configureStore) ->

  store = configureStore({
    studentList: {
      students: [],
      sort: {
        direction: 'asc',
        column: 'student_name'
      }
    },
    assignment: {
      published: window.ENV.GRADES_PUBLISHED
    },
    flashMessage: {
      error: false,
      message: '',
      time: Date.now()
    },
    urls: window.ENV.URLS,
  })

  React.render(ModerationApp(store: store), $('#assignment_moderation')[0])

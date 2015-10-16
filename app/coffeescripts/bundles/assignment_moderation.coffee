require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/store/configureStore'
], ($, React, ModerationApp, configureStore) ->

  ModerationAppFactory = React.createFactory ModerationApp

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

  React.render(ModerationAppFactory(store: store), $('#assignment_moderation')[0])

require [
  'jquery'
  'react'
  'react-dom'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/store/configureStore'
], ($, React, ReactDOM, ModerationApp, configureStore) ->

  ModerationAppFactory = React.createFactory ModerationApp

  store = configureStore({
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
      title: window.ENV.ASSIGNMENT_TITLE
    },
    flashMessage: {
      error: false,
      message: '',
      time: Date.now()
    },
    urls: window.ENV.URLS,
  })

  ReactDOM.render(ModerationAppFactory(store: store), $('#assignment_moderation')[0])

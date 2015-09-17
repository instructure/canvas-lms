require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
  'jsx/assignments/store/configureStore'
], ($, React, ModerationApp, configureStore) ->

  store = configureStore({
    moderationStage: [],
    students: [],
    urls: window.ENV.URLS
    flashMessage: {
      time: Date.now(),
      message: '',
      error: false
    },
    assignment: {
      published: window.ENV.GRADES_PUBLISHED
    }
  })

  React.render(ModerationApp(store: store), $('#assignment_moderation')[0])

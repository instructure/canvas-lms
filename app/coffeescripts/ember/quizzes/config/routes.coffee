define ->
  route = ->
    @route 'quizzes', path: '/', ->
      @route 'index', path: '/'
    @resource 'quiz', path: '/:quiz_id', ->
      @route 'show', path: '/'

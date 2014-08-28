define ->
  route = ->
    @route 'quizzes', path: '/', ->
      @route 'index', path: '/'
    @resource 'quiz', path: '/:quiz_id', ->
      @route 'show', path: '/'
      @route 'preview', path: '/preview'
      @route 'moderate', path: '/moderate'
      @route 'statistics', path: '/statistics'

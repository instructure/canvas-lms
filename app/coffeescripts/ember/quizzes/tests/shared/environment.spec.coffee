define ['../../shared/environment'], (environment) ->

  module 'environment',
    setup: ->
      environment.setEnv
        context_asset_string: 'course_10',
        current_user_id: 1,
        files_domain: 'localhost:3000'

  test 'computes course id correctly', ->
    equal environment.get('courseId'), 10, 'courseId'

  test 'returns false for permissions when not available', ->
    equal environment.get('canManage'), false

  test 'returns appropriate permissions when available', ->
    expect(2)
    environment.setEnv
      PERMISSIONS:
        manage: true
        update: true
    equal environment.get('canManage'), true
    equal environment.get('canUpdate'), true

  test 'returns false for flags when not available', ->
    equal environment.get('moderateEnabled'), false

  test 'returns appropriate flag status when available', ->
    environment.setEnv
      FLAGS:
        quiz_moderate: true
    equal environment.get('moderateEnabled'), true

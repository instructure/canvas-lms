define ['../../shared/environment'], (environment) ->

  module 'environment',
    setup: ->
      environment.setEnv
        context_asset_string: 'course_10',
        current_user_id: 1,
        files_domain: 'localhost:3000'

  test 'computes course id correctly', ->
    equal environment.get('courseId'), 10, 'courseId'

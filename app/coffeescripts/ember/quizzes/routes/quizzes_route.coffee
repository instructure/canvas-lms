define [
  'ember',
  'ic-ajax',
  '../shared/environment'
], (Ember, ajax, environment) ->

  # http://emberjs.com/guides/routing/
  # http://emberjs.com/api/classes/Ember.Route.html

  QuizzesRoute = Ember.Route.extend

    model: (params) ->
      environment.setEnv(ENV)
      id = environment.get('courseId')
      ajax("/api/v1/courses/#{id}/quizzes").then (result) ->
        result.response

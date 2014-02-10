define [
  'ember',
  '../shared/fetch_all_jsonapi',
  '../shared/environment'
], (Ember, fetchAll, environment) ->

  QuizzesRoute = Ember.Route.extend

    model: (params) ->
      environment.setEnv(ENV)
      id = environment.get('courseId')

      fetchAll("/api/v1/courses/#{id}/quizzes")

define [
  'backbone'
  'compiled/models/Observee'
], (Backbone, Observee) ->

  class ObserveeCollection extends Backbone.Collection
  
    url: -> 'api/v1/users/' + ENV.current_user_id + '/observer_enrollments'

    model: Observee
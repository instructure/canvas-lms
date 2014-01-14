define [
  'Backbone'
  'compiled/models/Conference'
], ({Collection}, Conference) ->

  class ConferenceCollection extends Collection
    model: Conference

    @optionProperty 'course_id'

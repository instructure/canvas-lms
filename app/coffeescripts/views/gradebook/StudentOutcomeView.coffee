define [
  'underscore'
  'Backbone'
  'jst/gradebook2/student_outcome_view'
], (_, Backbone, template) ->
  class StudentOutcomesView extends Backbone.View
    tagName: 'li'
    template: template
    toJSON: ->
      json = super
      _.extend({score_defined: _.isNumber(json.score)}, json)

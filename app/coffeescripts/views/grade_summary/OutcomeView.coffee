define [
  'underscore'
  'Backbone'
  'jst/grade_summary/outcome'
], (_, Backbone, template) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template
    toJSON: ->
      json = super
      _.extend({score_defined: _.isNumber(json.score)}, json)

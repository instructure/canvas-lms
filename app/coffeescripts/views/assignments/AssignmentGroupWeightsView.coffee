define [
  'Backbone'
  'jst/assignments/AssignmentGroupWeights'
], (Backbone, AssignmentGroupWeightsTemplate) ->

  class AssignmentGroupWeightsView extends Backbone.View
    template: AssignmentGroupWeightsTemplate
    tagName: 'tr'
    className: 'ag-weights-tr'

    findWeight: ->
      parseInt @$el.find('.group_weight_value').val()

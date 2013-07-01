define [
  'Backbone'
  'jst/assignments/teacher_index/AssignmentGroupWeights'
], (Backbone, AssignmentGroupWeightsTemplate) ->

  class AssignmentGroupWeightsView extends Backbone.View
    template: AssignmentGroupWeightsTemplate
    tagName: 'tr'
    className: 'ag-weights-tr'

    findWeight: ->
      parseInt @$el.find('.group_weight_value').val()
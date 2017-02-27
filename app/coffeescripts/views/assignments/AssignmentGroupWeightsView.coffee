define [
  'jquery'
  'compiled/util/round'
  'Backbone'
  'jst/assignments/AssignmentGroupWeights'
], ($, round, Backbone, AssignmentGroupWeightsTemplate) ->

  class AssignmentGroupWeightsView extends Backbone.View
    template: AssignmentGroupWeightsTemplate
    tagName: 'tr'
    className: 'ag-weights-tr'

    @optionProperty 'canChangeWeights'

    events:
      'blur .group_weight_value' : 'roundWeight'

    roundWeight: (e) ->
      value = $(e.target).val()
      rounded_value = round(parseFloat(value), 2)
      if isNaN(rounded_value)
        return
      else
        $(e.target).val(rounded_value)

    findWeight: ->
      round(parseFloat(@$el.find('.group_weight_value').val()), 2)

    toJSON: ->
      data = super
      data.canChangeWeights = @canChangeWeights
      data

define [
  'jquery'
  'compiled/util/round'
  'Backbone'
  'i18n!assignments'
  'jst/assignments/AssignmentGroupWeights'
  'jsx/shared/helpers/numberHelper'
], ($, round, Backbone, I18n, AssignmentGroupWeightsTemplate, numberHelper) ->

  class AssignmentGroupWeightsView extends Backbone.View
    template: AssignmentGroupWeightsTemplate
    tagName: 'tr'
    className: 'ag-weights-tr'

    @optionProperty 'canChangeWeights'

    events:
      'blur .group_weight_value' : 'roundWeight'

    roundWeight: (e) ->
      value = $(e.target).val()
      rounded_value = round(numberHelper.parse(value), 2)
      if isNaN(rounded_value)
        return
      else
        $(e.target).val(I18n.n(rounded_value))

    findWeight: ->
      round(numberHelper.parse(@$el.find('.group_weight_value').val()), 2)

    toJSON: ->
      data = super
      data.canChangeWeights = @canChangeWeights
      data

define [
  'compiled/util/round'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/assignments/AssignmentSettings'
], (round, _, DialogFormView, wrapper, assignmentSettingsTemplate) ->

  class AssignmentSettingsView extends DialogFormView
    template: assignmentSettingsTemplate
    wrapperTemplate: wrapper

    defaults:
      width: 450
      height: 500
      collapsedHeight: 175

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'change #apply_assignment_group_weights': 'toggleTableByClick'
      'keyup .group_weight_value': 'updateTotalWeight'
    )

    @optionProperty 'assignmentGroups'
    @optionProperty 'weightsView'

    initialize: ->
      super
      @weights = []

    openAgain: ->
      super
      @toggleTableByModel()
      @addAssignmentGroups()

    saveFormData: (data=null) ->
      for v in @weights
        new_weight = v.findWeight()
        v.model.set('group_weight', new_weight)
        v.model.save()
      super(data)

    onSaveSuccess: ->
      super
      @assignmentGroups.trigger 'change:groupWeights'

    toggleTableByModel: ->
      checked = @model.get('apply_assignment_group_weights')
      @toggleWeightsTable(checked)

    toggleTableByClick: (e) ->
      checked = $(e.currentTarget).is(':checked')
      @toggleWeightsTable(checked)

    toggleWeightsTable: (show) ->
      if show
        @$('#ag_weights_wrapper').show()
        @$('#apply_assignment_group_weights').prop('checked', true)
        @setDimensions(null, @defaults.height)
      else
        @$('#ag_weights_wrapper').hide()
        @$('#apply_assignment_group_weights').prop('checked', false)
        @setDimensions(null, @defaults.collapsedHeight)

    addAssignmentGroups: ->
      @clearWeights()
      total_weight = 0
      for g in @assignmentGroups.models
        #create view
        v = new @weightsView {model: g}
        v.render()
        #add to table
        @$el.find('#assignment_groups_weights tbody').append(v.el)
        @weights.push v
        #sum group weights
        total_weight += v.findWeight() || 0
      total_weight = round(total_weight,2)

      @$el.find('#percent_total').text(total_weight + "%")

    clearWeights: ->
      @weights = []
      @$el.find('#assignment_groups_weights tbody').empty()

    updateTotalWeight: ->
      total_weight = 0
      for v in @weights
        total_weight += v.findWeight() || 0
      total_weight = round(total_weight,2)
      @$el.find('#percent_total').text(total_weight + "%")

    toJSON: ->
      data = super
      data.course

define [
  'underscore'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/assignments/AssignmentSettings'
], (_, DialogFormView, wrapper, assignmentSettingsTemplate) ->

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
      @assignmentGroups.view.render()

    toggleTableByModel: ->
      checked = @model.get('apply_assignment_group_weights')
      @toggleWeightsTable(checked)

    toggleTableByClick: (e) ->
      checked = $(e.currentTarget).is(':checked')
      @toggleWeightsTable(checked)

    toggleWeightsTable: (show) ->
      if show
        @$el.find('#ag_weights_wrapper').show()
        @setDimensions(null, @defaults.height)
      else
        @$el.find('#ag_weights_wrapper').hide()
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

      @$el.find('#percent_total').html(total_weight + "%")

    clearWeights: ->
      @weights = []
      @$el.find('#assignment_groups_weights tbody').empty()

    updateTotalWeight: ->
      total_weight = 0
      for v in @weights
        total_weight += v.findWeight() || 0
      @$el.find('#percent_total').html(total_weight + "%")

    toJSON: ->
      data = super
      data.course

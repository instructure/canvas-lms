define [
  'jquery'
  'i18n!assignments'
  'compiled/util/round'
  'jsx/shared/helpers/numberHelper'
  'underscore'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/assignments/AssignmentSettings'
], ($, I18n, round, numberHelper, _, DialogFormView, wrapper, assignmentSettingsTemplate) ->

  class AssignmentSettingsView extends DialogFormView
    template: assignmentSettingsTemplate
    wrapperTemplate: wrapper

    defaults:
      width: 450
      height: 500
      collapsedHeight: 300

    events: _.extend({}, @::events,
      'click .dialog_closer': 'cancel'
      'click #apply_assignment_group_weights': 'toggleTableByClick'
      'keyup .group_weight_value': 'updateTotalWeight'
    )

    @optionProperty 'assignmentGroups'
    @optionProperty 'weightsView'
    @optionProperty 'userIsAdmin'

    initialize: ->
      super
      @weights = []

    validateFormData: ->
      errors = {}
      weights = @$el.find('.group_weight_value')
      _.each weights, (weight) =>
        weight_value = $(weight).val()
        field_selector = weight.getAttribute("name")
        if (weight_value && isNaN(numberHelper.parse(weight_value)))
          errors[field_selector] = [{type: 'number', message: I18n.t("Must be a valid number")}]
      errors

    openAgain: ->
      super
      @toggleTableByModel()
      @addAssignmentGroups()

    canChangeWeights: ->
      @userIsAdmin or !_.any @assignmentGroups.models, (ag) ->
        ag.anyAssignmentInClosedGradingPeriod()

    submit: (event) ->
      if @canChangeWeights()
        super(event)
      else
        event?.preventDefault()

    saveFormData: (data=null) ->
      for v in @weights
        new_weight = v.findWeight()
        v.model.set('group_weight', new_weight)
        v.model.save()
      super(data)

    cancel: ->
      if @canChangeWeights()
        @close()

    onSaveSuccess: ->
      super
      @assignmentGroups.trigger 'change:groupWeights'
      checked = @model.get('apply_assignment_group_weights')
      @trigger('weightedToggle', checked)

    toggleTableByModel: ->
      checked = @model.get('apply_assignment_group_weights')
      @toggleWeightsTable(checked)

    toggleTableByClick: (e) ->
      if @canChangeWeights()
        checked = $(e.currentTarget).is(':checked')
        @toggleWeightsTable(checked)
      else
        e.preventDefault()

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
      canChangeWeights = @canChangeWeights()
      total_weight = 0
      for model in @assignmentGroups.models
        #create view
        v = new @weightsView {model, canChangeWeights: canChangeWeights}
        v.render()
        #add to table
        @$el.find('#assignment_groups_weights tbody').append(v.el)
        @weights.push v
        #sum group weights
        total_weight += model.get('group_weight') || 0
      total_weight = round(total_weight,2)

      @$el.find('#percent_total').text(I18n.n(total_weight, { percentage: true }))

    clearWeights: ->
      @weights = []
      @$el.find('#assignment_groups_weights tbody').empty()

    updateTotalWeight: ->
      total_weight = 0
      for v in @weights
        total_weight += v.findWeight() || 0
      total_weight = round(total_weight,2)
      @$el.find('#percent_total').text(I18n.n(total_weight, { percentage: true }))

    toJSON: ->
      data = super
      data.course
      data.canChangeWeights = @canChangeWeights()
      data

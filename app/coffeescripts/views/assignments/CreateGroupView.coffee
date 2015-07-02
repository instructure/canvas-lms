define [
  'compiled/util/round'
  'i18n!assignments'
  'jquery'
  'underscore'
  'compiled/models/AssignmentGroup'
  'compiled/collections/NeverDropCollection'
  'compiled/views/assignments/NeverDropCollectionView'
  'compiled/views/DialogFormView'
  'jst/assignments/CreateGroup'
  'jst/EmptyDialogFormWrapper'
], (round, I18n, $, _, AssignmentGroup, NeverDropCollection, NeverDropCollectionView, DialogFormView, template, wrapper) ->

  SHORT_HEIGHT = 250

  class CreateGroupView extends DialogFormView
    defaults:
      width: 600
      height: 500

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'blur .group_weight': 'roundWeight'
    )

    els:
      '.never_drop_rules_group': '$neverDropContainer'

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroups'
    @optionProperty 'assignmentGroup'
    @optionProperty 'course'

    messages:
      non_number: I18n.t('non_number', 'You must use a number')
      positive_number: I18n.t('positive_number', 'You must use a positive number')
      max_number: I18n.t('higher_than_max', 'You cannot use a number greater than the number of assignments')
      no_name_error: I18n.t('no_name_error', 'A name is required')
      name_too_long_error: I18n.t('name_too_long_error', 'Name is too long')

    initialize: ->
      super
      #@assignmentGroup will be defined when editing
      @model = @assignmentGroup or new AssignmentGroup(assignments: [])

    onSaveSuccess: ->
      super
      # meaning we are editing
      if @assignmentGroup
        # trigger instead of calling render directly
        @model.collection.trigger 'render', @model.collection
      else
        @assignmentGroups.add(@model)
        @model = new AssignmentGroup(assignments: [])

        @render()

    getFormData: ->
      data = super
      if data.rules
        delete data.rules.drop_lowest if _.contains(["", "0"], data.rules.drop_lowest)
        delete data.rules.drop_highest if _.contains(["", "0"], data.rules.drop_highest)
        delete data.rules.never_drop if data.rules.never_drop?.length == 0
      data

    validateFormData: (data) ->
      max = 0
      if @assignmentGroup
        as = @assignmentGroup.get('assignments')
        max = as.size() if as?
      errors = {}
      if data.name.length > 255
        errors["name"] = [{type: 'name_too_long_error', message: @messages.name_too_long_error}]
      if data.name == ""
        errors["name"] = [{type: 'no_name_error', message: @messages.no_name_error}]
      _.each data.rules, (value, name) =>
        # don't want to validate the never_drop field
        return if name is 'never_drop'
        val = parseInt(value)
        field = "rules[#{name}]"
        if isNaN(val)
          errors[field] = [{type: 'number', message: @messages.non_number}]
        if val < 0
          errors[field] = [{type: 'positive_number', message: @messages.positive_number}]
        if val > max
          errors[field] = [{type: 'maximum', message: @messages.max_number}]
      errors

    showWeight: ->
      course = @course or @model.collection?.course
      course?.get('apply_assignment_group_weights')

    checkGroupWeight: ->
      if @showWeight()
        @$el.find('.group_weight').removeAttr("disabled")
      else
        @$el.find('.group_weight').attr("disabled", "disabled")

    getNeverDrops: ->
      @$neverDropContainer.empty()
      rules = @model.rules()
      @never_drops = new NeverDropCollection [],
        assignments: @model.get('assignments')
        ag_id: @model.get('id') or 'new'

      @ndCollectionView = new NeverDropCollectionView
        collection: @never_drops

      @$neverDropContainer.append @ndCollectionView.render().el
      if rules && rules.never_drop
        @never_drops.reset rules.never_drop,
          parse: true

    roundWeight: (e) ->
      value = $(e.target).val()
      rounded_value = round(parseFloat(value), 2)
      $(e.target).val(rounded_value)

    toJSON: ->
      data = @model.toJSON()
      _.extend(data, {
        disable_weight: !@showWeight()
        group_weight: if @showWeight() then data.group_weight else null
        label_id: @model.get('id') or 'new'
        drop_lowest: @model.rules()?.drop_lowest or 0
        drop_highest: @model.rules()?.drop_highest or 0
        editable_drop: @model.get('assignments').length > 0
        #Safari is not fully compatiable with html5 validation - needs to be set to text instead to ensure our validations work
        number_input: if !!navigator.userAgent.match(/Version\/[\d\.]+.*Safari/) then "text" else "number"
      })

    openAgain: ->
      if @model.get('assignments').length == 0
        @setDimensions(this.defaults.width, SHORT_HEIGHT)

      super
      @checkGroupWeight()
      @getNeverDrops()

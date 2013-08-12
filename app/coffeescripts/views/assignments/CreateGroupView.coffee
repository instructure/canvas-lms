define [
  'i18n!assignments'
  'underscore'
  'compiled/models/AssignmentGroup'
  'compiled/views/assignments/NeverDropView'
  'compiled/views/DialogFormView'
  'jst/assignments/CreateGroup'
  'jst/EmptyDialogFormWrapper'
], (I18n, _, AssignmentGroup, NeverDropView, DialogFormView, template, wrapper) ->

  class CreateGroupView extends DialogFormView

    defaults:
      width: 600
      height: 500

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'click .add_never_drop': 'addNeverDrop'
      'click .remove_never_drop': 'removeNeverDrop'
    )

    els:
      '.add_never_drop': '$addNeverDropLink'
      '.never_drop': '$neverDropContainer'

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroups'
    @optionProperty 'assignmentGroup'
    @optionProperty 'assignments'
    @optionProperty 'course'

    initialize: ->
      @never_drops = []
      super
      @model = @assignmentGroup or new AssignmentGroup

    onSaveSuccess: ->
      super
      if @assignmentGroup # meaning we are editing
        @model.collection.view.render()
      else
        @assignmentGroups.add(@model)
        @model = new AssignmentGroup

      @render()

    getFormData: ->
      data = super
      delete data.rules.drop_lowest if _.contains(["", "0"], data.rules.drop_lowest )
      delete data.rules.drop_highest if _.contains(["", "0"], data.rules.drop_highest )
      delete data.rules.never_drop if data.rules.never_drop?.length == 0
      data

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
      if rules && rules.never_drop
        for drop in rules.never_drop
          assignment = @findAssignment(drop)
          model = new Backbone.Model
            id: @never_drops.length
            chosen: assignment[0].name()
            chosen_id: assignment[0].id
            label_id: @model.get('id') or 'new'

          @createNeverDrop model

    findAssignment: (id) ->
      @assignments.filter (a) ->
        a.id == id

    toggleAddNeverDropLinkText: ->
      if @$neverDropContainer.find('.never_drop_rule').length == 0
        text = I18n.t('add_first_never_drop_rule', 'Add an assignment')
      else
        text = I18n.t('add_another_never_drop_rule', 'Add another assignment')
      @$addNeverDropLink.text(text)

    addNeverDrop: (ev) ->
      ev.preventDefault()
      model = new Backbone.Model
        id: @never_drops.length
        assignments: @assignments
        label_id: @model.get('id') or 'new'

      @createNeverDrop model
      @toggleAddNeverDropLinkText()

    createNeverDrop: (model) ->
      view = new NeverDropView {model: model}
      view.render()
      @insertNeverDrop view

    insertNeverDrop: (view) ->
      @never_drops.push view
      @$neverDropContainer.append view.el
      $(view.el).find('select').focus()

    removeNeverDrop: (event) ->
      event.preventDefault()
      index = parseInt $(event.currentTarget).data('ruleId')
      @never_drops[index].remove()
      delete @never_drops[index]
      @toggleAddNeverDropLinkText()

    toJSON: ->
      data = @model.toJSON()
      _.extend(data, {
        disable_weight: !@showWeight()
        group_weight: if @showWeight() then data.group_weight else null
        label_id: @model.get('id') or 'new'
        drop_lowest: @model.rules()?.drop_lowest or 0
        drop_highest: @model.rules()?.drop_highest or 0
        editable_never_drop: @assignments?.length > 0
      })

    openAgain: ->
      super
      @checkGroupWeight()
      @getNeverDrops()
      @toggleAddNeverDropLinkText()

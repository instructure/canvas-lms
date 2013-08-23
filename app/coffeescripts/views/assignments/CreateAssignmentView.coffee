define [
  'underscore'
  'compiled/views/DialogFormView'
  'compiled/models/Assignment'
  'jst/assignments/CreateAssignment'
  'jst/EmptyDialogFormWrapper'
  'jquery.instructure_date_and_time'
], (_, DialogFormView, Assignment, template, wrapper) ->

  class CreateAssignmentView extends DialogFormView
    defaults:
      width: 500
      height: 330

    events: _.extend({}, @::events,
      'click .dialog_closer': 'close'
      'click .more_options': 'moreOptions'
    )

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroup'

    initialize: ->
      super
      @generateNewModel()

    onSaveSuccess: ->
      super
      @assignmentGroup.get('assignments').add(@model)

    moreOptions: ->
      data = @getFormData()
      data.assignment_group_id = @assignmentGroup.get('id')
      params = ''
      separator = '?'
      _.each ['submission_types', 'name', 'due_at', 'points_possible', 'assignment_group_id'], (field) ->
        if data[field] && data[field] != ''
          params += "#{separator}#{field}=#{data[field]}"
          separator = '&' if separator == '?'

      window.location = "#{ENV.URLS.new_assignment_url}#{params}"

    generateNewModel: ->
      @model = new Assignment
      @model.assignmentGroupId(@assignmentGroup.id) if @assignmentGroup

    toJSON: ->
      json = @model.toJSON()
      _.extend(json, {
        label_id: @assignmentGroup.get('id')
      })

    openAgain: ->
      @generateNewModel()
      @render()
      super
      if !@$el.find(".datetime_field").hasClass("datetime_field_enabled")
        @$el.find(".datetime_field").datetime_field()

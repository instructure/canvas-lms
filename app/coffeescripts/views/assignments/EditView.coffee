define [
  'INST'
  'i18n!assignment'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jquery'
  'wikiSidebar'
  'jst/assignments/EditView'
  'compiled/models/TurnitinSettings'
  'compiled/views/assignments/TurnitinSettingsDialog'
  'compiled/fn/preventDefault'
  'compiled/views/calendar/MissingDateDialogView'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jqueryui/dialog'
  'jquery.toJSON'
  'compiled/jquery.rails_flash_notifications',
  'compiled/jquery/toggleAccessibly',
], (INST, I18n, ValidatedFormView, _, $, wikiSidebar, template,
TurnitinSettings, TurnitinSettingsDialog, preventDefault, MissingDateDialog,
AssignmentGroupSelector, GroupCategorySelector, toggleAccessibly) ->

  class EditView extends ValidatedFormView

    template: template

    dontRenableAfterSaveSuccess: true

    ASSIGNMENT_GROUP_SELECTOR = '#assignment_group_selector'
    DUE_DATE_AREA = '#assignment_due_date_controls'
    DUE_AT = '[name="due_at"]'
    DESCRIPTION = '[name="description"]'
    SUBMISSION_TYPE = '[name="submission_type"]'
    ONLINE_SUBMISSION_TYPES = '#assignment_online_submission_types'
    NAME = '[name="name"]'
    ALLOW_FILE_UPLOADS = '#assignment_online_upload'
    RESTRICT_FILE_UPLOADS = '#assignment_restrict_file_extensions'
    RESTRICT_FILE_UPLOADS_OPTIONS = '#restrict_file_extensions_container'
    ALLOWED_EXTENSIONS = '#allowed_extensions_container'
    ADVANCED_ASSIGNMENT_OPTIONS = '#advanced_assignment_options'
    TURNITIN_ENABLED = '#assignment_turnitin_enabled'
    ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
    ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS = '#assignment_toggle_advanced_options'
    GRADING_TYPE_SELECTOR = '#grading_type_selector'
    GRADED_ASSIGNMENT_FIELDS = '#graded_assignment_fields'
    EXTERNAL_TOOL_SETTINGS = '#assignment_external_tool_settings'
    GROUP_CATEGORY_SELECTOR = '#group_category_selector'
    PEER_REVIEWS_FIELDS = '#assignment_peer_reviews_fields'
    EXTERNAL_TOOLS_URL = '#assignment_external_tool_tag_attributes_url'
    EXTERNAL_TOOLS_NEW_TAB = '#assignment_external_tool_tag_attributes_new_tab'

    els: _.extend({}, @::els, do ->
      els = {}
      els["#{ASSIGNMENT_GROUP_SELECTOR}"] = '$assignmentGroupSelector'
      els["#{DUE_DATE_AREA}"] = '$dueDateArea'
      els["#{DUE_AT}"] = '$dueAt'
      els["#{DESCRIPTION}"] = '$description'
      els["#{SUBMISSION_TYPE}"] = '$submissionType'
      els["#{ONLINE_SUBMISSION_TYPES}"] = '$onlineSubmissionTypes'
      els["#{NAME}"] = '$name'
      els["#{ALLOW_FILE_UPLOADS}"] = '$allowFileUploads'
      els["#{RESTRICT_FILE_UPLOADS}"] = '$restrictFileUploads'
      els["#{RESTRICT_FILE_UPLOADS_OPTIONS}"] = '$restrictFileUploadsOptions'
      els["#{ALLOWED_EXTENSIONS}"] = '$allowedExtensions'
      els["#{ADVANCED_ASSIGNMENT_OPTIONS}"] = '$advancedAssignmentOptions'
      els["#{TURNITIN_ENABLED}"] = '$turnitinEnabled'
      els["#{ADVANCED_TURNITIN_SETTINGS}"] = '$advancedTurnitinSettings'
      els["#{ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS}"] = '$assignmentToggleAdvancedOptions'
      els["#{GRADING_TYPE_SELECTOR}"] = '$gradingTypeSelector'
      els["#{GRADED_ASSIGNMENT_FIELDS}"] = '$gradedAssignmentFields'
      els["#{EXTERNAL_TOOL_SETTINGS}"] = '$externalToolSettings'
      els["#{GROUP_CATEGORY_SELECTOR}"] = '$groupCategorySelector'
      els["#{PEER_REVIEWS_FIELDS}"] = '$peerReviewsFields'
      els["#{EXTERNAL_TOOLS_URL}"] = '$externalToolsUrl'
      els["#{EXTERNAL_TOOLS_NEW_TAB}"] = '$externalToolsNewTab'
      els
    )

    events: _.extend({}, @::events, do ->
      events = {}
      events["click .cancel_button"] = 'handleCancel'
      events["click #{ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS}"] = 'toggleAdvancedOptions'
      events["change #{SUBMISSION_TYPE}"] = 'handleSubmissionTypeChange'
      events["change #{RESTRICT_FILE_UPLOADS}"] = 'handleRestrictFileUploadsChange'
      events["click #{ADVANCED_TURNITIN_SETTINGS}"] = 'showTurnitinDialog'
      events["change #{TURNITIN_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
      events["change #{ALLOW_FILE_UPLOADS}"] = 'toggleRestrictFileUploads'
      events["click #{EXTERNAL_TOOLS_URL}"] = 'showExternalToolsDialog'
      events
    )

    @child 'assignmentGroupSelector', "#{ASSIGNMENT_GROUP_SELECTOR}"
    @child 'gradingTypeSelector', "#{GRADING_TYPE_SELECTOR}"
    @child 'groupCategorySelector', "#{GROUP_CATEGORY_SELECTOR}"
    @child 'peerReviewsSelector', "#{PEER_REVIEWS_FIELDS}"

    initialize: (options) ->
      super
      @assignment = @model
      @dueDateOverrideView = options.views['js-assignment-overrides']
      @model.on 'sync', -> window.location = @get 'html_url'
      @gradingTypeSelector.on 'change:gradingType', @handleGradingTypeChange

    handleCancel: (ev) =>
      ev.preventDefault()
      window.location = ENV.CANCEL_TO if ENV.CANCEL_TO?

    showingAdvancedOptions: =>
      ariaExpanded = @$advancedAssignmentOptions.attr('aria-expanded')
      ariaExpanded == 'true' or ariaExpanded == true

    toggleAdvancedOptions: (ev) =>
      ev.preventDefault()
      $(ev.currentTarget).focus() # to ensure its errorBox gets cleaned up (if it has one)
      expanded = @showingAdvancedOptions()
      @$advancedAssignmentOptions.attr('aria-expanded', !expanded)
      @$advancedAssignmentOptions.toggle(!expanded)
      if expanded
        @$dueDateArea.show()
        text = I18n.t('show_advanced_options', 'Show Advanced Options') + ' ▼'
      else
        @$dueDateArea.hide()
        text = I18n.t('hide_advanced_options', 'Hide Advanced Options') + ' ▲'
      @$assignmentToggleAdvancedOptions.text text

    showTurnitinDialog: (ev) =>
      ev.preventDefault()
      turnitinDialog = new TurnitinSettingsDialog(model: @assignment.get('turnitin_settings'))
      turnitinDialog.render().on 'settings:change', (settings) =>
        @assignment.set 'turnitin_settings', new TurnitinSettings(settings)
        turnitinDialog.off()
        turnitinDialog.remove()

    showExternalToolsDialog: =>
      # TODO: don't use this dumb thing
      INST.selectContentDialog
        dialog_title: I18n.t('select_external_tool_dialog_title', 'Configure External Tool')
        select_button_text: I18n.t('buttons.select_url', 'Select'),
        no_name_input: true,
        submit: (data) =>
          @$externalToolsUrl.val(data['item[url]'])
          @$externalToolsNewTab.prop('checked', data['item[new_tab]'] == '1')

    toggleRestrictFileUploads: =>
      @$restrictFileUploadsOptions.toggleAccessibly @$allowFileUploads.prop('checked')

    toggleAdvancedTurnitinSettings: (ev) =>
      ev.preventDefault()
      @$advancedTurnitinSettings.toggleAccessibly @$turnitinEnabled.prop('checked')

    handleRestrictFileUploadsChange: =>
      @$allowedExtensions.toggleAccessibly @$restrictFileUploads.prop('checked')

    handleGradingTypeChange: (gradingType) =>
      @$gradedAssignmentFields.toggleAccessibly gradingType != 'not_graded'
      @handleSubmissionTypeChange(null)

    handleSubmissionTypeChange: (ev) =>
      subVal = @$submissionType.val()
      @$onlineSubmissionTypes.toggleAccessibly subVal == 'online'
      @$externalToolSettings.toggleAccessibly subVal == 'external_tool'
      @$groupCategorySelector.toggleAccessibly subVal != 'external_tool'
      @$peerReviewsFields.toggleAccessibly subVal != 'external_tool'

    afterRender: =>
      @_attachDatepickerToDateFields()
      @_attachEditorToDescription()
      $ @_initializeWikiSidebar
      this

    toJSON: =>
      data = @assignment.toView()
      _.extend data,
        kalturaEnabled: ENV?.KALTURA_ENABLED or false
        isLargeRoster: ENV?.IS_LARGE_ROSTER or false
        submissionTypesFrozen: _.include(data.frozenAttributes, 'submission_types')

    _attachEditorToDescription: =>
      @$description.editorBox()
      $('.rte_switch_views_link').click preventDefault => @$description.editorBox('toggle')

    _attachDatepickerToDateFields: =>
      if @assignment.isSimple()
        @$dueAt.datetime_field()

    _initializeWikiSidebar: =>
      # $("#sidebar_content").hide()
      unless wikiSidebar.inited
        wikiSidebar.init()
        $.scrollSidebar()
      wikiSidebar.attachToEditor(@$description).show()

    # -- Data for Submitting --
    getFormData: =>
      data = super
      data = @_inferSubmissionTypes data
      data = @_filterAllowedExtensions data
      unless ENV?.IS_LARGE_ROSTER
        data = @groupCategorySelector.filterFormData data
      # should update the date fields.. pretty hacky.
      if @showingAdvancedOptions()
        @dueDateOverrideView.updateOverrides()
        defaultDates = @dueDateOverrideView.getDefaultDueDate()
        data.lock_at = defaultDates?.get('lock_at') or null
        data.unlock_at = defaultDates?.get('unlock_at') or null
        data.due_at = defaultDates?.get('due_at') or null
        data.assignment_overrides = @dueDateOverrideView.getOverrides()
      else
        unfudged = $.unfudgeDateForProfileTimezone(data.due_at)
        data.due_at = $.dateToISO8601UTC(unfudged) if unfudged?
      return data

    submit: (event) =>
      event.preventDefault()
      event.stopPropagation()
      @dueDateOverrideView.updateOverrides()
      if @dueDateOverrideView.containsSectionsWithoutOverrides()
        sections = @dueDateOverrideView.sectionsWithoutOverrides()
        missingDateDialog = new MissingDateDialog
          validationFn: -> sections
          labelFn: (section) -> section.get 'name'
          success: =>
            @model.setNullDates()
            ValidatedFormView::submit.call(this)
        missingDateDialog.cancel = (e) ->
          missingDateDialog.$dialog.dialog('close').remove()

        missingDateDialog.render()
      else
        super

    _inferSubmissionTypes: (assignmentData) =>
      if assignmentData.grading_type == 'not_graded'
        assignmentData.submission_types = ['not_graded']
      else if assignmentData.submission_type == 'online'
        types = _.select _.keys(assignmentData.online_submission_types), (k) ->
          assignmentData.online_submission_types[k] is '1'
        assignmentData.submission_types = types
      else
        assignmentData.submission_types = [assignmentData.submission_type]
      delete assignmentData.online_submission_type
      delete assignmentData.online_submission_types
      assignmentData

    _filterAllowedExtensions: (data) =>
      restrictFileExtensions = data.restrict_file_extensions
      delete data.restrict_file_extensions
      if restrictFileExtensions is '1'
        data.allowed_extensions = _.select data.allowed_extensions.split(","), (ext) ->
          $.trim(ext.toString()).length > 0
      else
        data.allowed_extensions = null
      data

    # -- Pre-Save Validations --

    fieldSelectors: _.extend(
      { assignmentToggleAdvancedOptions: '#assignment_toggle_advanced_options'},
      AssignmentGroupSelector::fieldSelectors,
      GroupCategorySelector::fieldSelectors
    )

    showErrors: (errors) ->
      # override view handles displaying override errors, remove them
      # before calling super
      # see getFormValues in DueDateView.coffee
      delete errors.assignmentOverrides
      super(errors)

    validateBeforeSave: (data, errors) =>
      errors = @_validateTitle data, errors
      errors = @_validateSubmissionTypes data, errors
      errors = @_validateAllowedExtensions data, errors
      errors = @assignmentGroupSelector.validateBeforeSave(data, errors)
      unless ENV?.IS_LARGE_ROSTER
        errors = @groupCategorySelector.validateBeforeSave(data, errors)
      errors = @_validatePointsPossible(data, errors)
      errors = @_validatePercentagePoints(data, errors)
      errors = @_validateAdvancedOptions(data, errors)
      data2 =
        assignment_overrides: @dueDateOverrideView.getAllDates(data)
      errors = @dueDateOverrideView.validateBeforeSave(data2,errors)
      errors

    _validateTitle: (data, errors) =>
      frozenTitle = _.contains(@model.frozenAttributes(), "title")

      if !frozenTitle and (!data.name or $.trim(data.name.toString()).length == 0)
        errors["name"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      errors


    _validateSubmissionTypes: (data, errors) =>
      if data.submission_type == 'online' and data.submission_types.length == 0
        errors["online_submission_types[online_text_entry]"] = [
          message: I18n.t 'at_least_one_submission_type', 'Please choose at least one submission type'
        ]
      errors

    _validateAllowedExtensions: (data, errors) =>
      if data.allowed_extensions and data.allowed_extensions.length == 0
        errors["allowed_extensions"] = [
          message: I18n.t 'at_least_one_file_type', 'Please specify at least one allowed file type'
        ]
      errors

    _validatePointsPossible: (data, errors) =>
      frozenPoints = _.contains(@model.frozenAttributes(), "points_possible")

      if !frozenPoints and data.points_possible and isNaN(parseFloat(data.points_possible))
        errors["points_possible"] = [
          message: I18n.t 'points_possible_number', 'Points possible must be a number'
        ]
      errors

    # Require points possible > 0
    # if grading type === percent
    _validatePercentagePoints: (data, errors) =>
      if data.grading_type == 'percent' and (data.points_possible == "0" or isNaN(parseFloat(data.points_possible)))
        errors["points_possible"] = [
          message: I18n.t 'percentage_points_possible', 'Points possible must be more than 0 for percentage grading'
        ]
      errors

    # add an extra error box if errors are hidden
    _validateAdvancedOptions: (data, errors) =>
      ariaExpanded = @$advancedAssignmentOptions.attr('aria-expanded')
      expanded = ariaExpanded == 'true' or ariaExpanded == true
      error_keys = _.without(_.keys(errors), "name", "points_possible")
      if error_keys.length > 0 and !expanded
        errors["assignmentToggleAdvancedOptions"] = [
          message: I18n.t 'advanced_options_errors', 'There were errors on one or more advanced options'
        ]
      errors

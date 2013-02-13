define [
  'INST'
  'i18n!assignment'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jquery'
  'wikiSidebar'
  'jst/assignments/EditView'
  'compiled/models/TurnitinSettings'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'compiled/views/assignments/TurnitinSettingsDialog'
  'grading_standards'
  'compiled/fn/preventDefault'
  'compiled/views/calendar/MissingDateDialogView'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jqueryui/dialog'
  'jquery.toJSON'
  'compiled/jquery.rails_flash_notifications',
], (INST, I18n, ValidatedFormView, _, $, wikiSidebar, template,
TurnitinSettings, AssignmentGroupSelector, GroupCategorySelector,
PeerReviewsSelector, TurnitinSettingsDialog, showGradingSchemeDialog,
preventDefault, MissingDateDialog) ->

  class EditView extends ValidatedFormView

    template: template

    dontRenableAfterSaveSuccess: true

    DUE_DATE_AREA = '#assignment_due_date_controls'
    DUE_AT = '[name="due_at"]'
    UNLOCK_AT = '[name="unlock_at"]'
    LOCK_AT = '[name="lock_at"]'
    DESCRIPTION = '[name="description"]'
    SUBMISSION_TYPE = '[name="submission_type"]'
    ONLINE_SUBMISSION_TYPES = '#assignment_online_submission_types'
    GRADING_TYPE = '[name="grading_type"]'
    NAME = '[name="name"]'
    ALLOW_FILE_UPLOADS = '[name="online_submission_types[online_upload]"]'
    RESTRICT_FILE_UPLOADS = '#restrict_file_extensions_container'
    ALLOWED_EXTENSIONS = '#allowed_extensions_container'
    ADVANCED_ASSIGNMENT_OPTIONS = '#advanced_assignment_options'
    TURNITIN_ENABLED = '[name="turnitin_enabled"]'
    ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
    ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS = '#assignment_toggle_advanced_options'
    GRADED_ASSIGNMENT_FIELDS = '#graded_assignment_fields'
    EXTERNAL_TOOL_SETTINGS = '#assignment_external_tool_settings'
    GROUP_CATEGORY_SELECTOR = '#group_category_selector'
    PEER_REVIEWS_FIELDS = '#assignment_peer_reviews_fields'
    EXTERNAL_TOOLS_URL = '#assignment_external_tool_tag_attributes_url'
    EXTERNAL_TOOLS_NEW_TAB = '#assignment_external_tool_tag_attributes_new_tab'
    VIEW_GRADING_LEVELS = '#view-grading-levels'

    initialize: ( options ) ->
      @assignment = @model
      {views} = options
      @dueDateOverrideView = views['js-assignment-overrides']
      @model.on 'sync', -> window.location = @get 'html_url'

    initializeSubviews: =>
      @assignmentGroupSelector or= new AssignmentGroupSelector
        el: '#assignment_group_selector'
        parentModel: @assignment
        assignmentGroups: ENV?.ASSIGNMENT_GROUPS || []
      unless ENV?.IS_MOOC
        @groupCategorySelector or= new GroupCategorySelector
          el: GROUP_CATEGORY_SELECTOR
          parentModel: @assignment
          groupCategories: ENV?.GROUP_CATEGORIES || []
        @peerReviewsSelector or= new PeerReviewsSelector
          el: PEER_REVIEWS_FIELDS
          parentModel: @assignment

    events: _.extend({}, @::events, do ->
      events = {}
      events["click .cancel_button"] = 'handleCancel'
      events["click #{ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS}"] = 'toggleAdvancedOptions'
      events["change #{SUBMISSION_TYPE}"] = 'handleSubmissionTypeChange'
      events["change #{GRADING_TYPE}"] = 'handleGradingTypeChange'
      events["change #{RESTRICT_FILE_UPLOADS}"] = 'handleRestrictFileUploadsChange'
      events["click #{ADVANCED_TURNITIN_SETTINGS}"] = 'showTurnitinDialog'
      events["change #{TURNITIN_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
      events["change #{ALLOW_FILE_UPLOADS}"] = 'toggleRestrictFileUploads'
      events["click #{EXTERNAL_TOOLS_URL}"] = 'showExternalToolsDialog'
      events["click .edit_letter_grades_link"] = 'showGradingSchemeDialog'
      events
    )

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

    showGradingSchemeDialog: (ev) =>
      # TODO: clean up. slightly dependent on grading_standards.js
      ev.preventDefault()
      $("#edit_letter_grades_form").dialog
        title: I18n.t('titles.grading_scheme_info', "View/Edit Grading Scheme"),
        width: 600,
        height: 310,
        close: -> $(ev.target).focus()

    toggleRestrictFileUploads: =>
      @showAccessibly @$restrictFileUploads, @$allowFileUploads.prop('checked')

    toggleAdvancedTurnitinSettings: (ev) =>
      ev.preventDefault()
      @showAccessibly @$advancedTurnitinSettings, @$turnitinEnabled.prop('checked')

    handleRestrictFileUploadsChange: =>
      @showAccessibly @$allowedExtensions, @$restrictFileUploads.find('input').prop('checked')

    handleGradingTypeChange: (ev) =>
      gradingType = @$gradingType.val()
      @showAccessibly @$gradedAssignmentFields, gradingType != 'not_graded'
      @showAccessibly @$viewGradingLevels, gradingType == 'letter_grade'

    handleSubmissionTypeChange: (ev) =>
      subVal = @$submissionType.val()
      @showAccessibly(@$onlineSubmissionTypes,  subVal == 'online')
      @showAccessibly(@$externalToolSettings, subVal == 'external_tool')
      @showAccessibly(@$groupCategorySelector, subVal != 'external_tool')
      @showAccessibly(@$peerReviewsFields, subVal != 'external_tool')

    _findElements: =>
      @$dueAt = @$ DUE_AT
      @$dueDateArea = @$ DUE_DATE_AREA
      @$unlockAt = @$ UNLOCK_AT
      @$lockAt = @$ LOCK_AT
      @$description = @$ DESCRIPTION
      @$submissionType = @$ SUBMISSION_TYPE
      @$onlineSubmissionTypes = @$ ONLINE_SUBMISSION_TYPES
      @$gradingType = @$ GRADING_TYPE
      @$name = @$ NAME
      @$allowFileUploads = @$ ALLOW_FILE_UPLOADS
      @$restrictFileUploads = @$ RESTRICT_FILE_UPLOADS
      @$allowedExtensions = @$ ALLOWED_EXTENSIONS
      @$turnitinEnabled = @$ TURNITIN_ENABLED
      @$advancedTurnitinSettings = @$ ADVANCED_TURNITIN_SETTINGS
      @$advancedAssignmentOptions = @$ ADVANCED_ASSIGNMENT_OPTIONS
      @$assignmentToggleAdvancedOptions = @$ ASSIGNMENT_TOGGLE_ADVANCED_OPTIONS
      @$gradedAssignmentFields = @$ GRADED_ASSIGNMENT_FIELDS
      @$externalToolSettings = @$ EXTERNAL_TOOL_SETTINGS
      @$groupCategorySelector = @$ GROUP_CATEGORY_SELECTOR
      @$peerReviewsFields = @$ PEER_REVIEWS_FIELDS
      @$externalToolsUrl = @$ EXTERNAL_TOOLS_URL
      @$externalToolsNewTab = @$ EXTERNAL_TOOLS_NEW_TAB
      @$viewGradingLevels = @$(VIEW_GRADING_LEVELS)

    showAccessibly: ($element, visible) ->
      if visible
        $element.show()
        $element.attr('aria-expanded', 'true')
      else
        $element.hide()
        $element.attr('aria-expanded', 'false')

    render: =>
      super
      @initializeSubviews()
      @assignmentGroupSelector.render()
      unless ENV?.IS_MOOC
        @groupCategorySelector.render()
        @peerReviewsSelector.render()
      @_findElements()
      @_attachDatepickerToDateFields()
      @_attachEditorToDescription()
      $ @_initializeWikiSidebar
      this

    toJSON: =>
      _.extend @assignment.toView(),
        kalturaEnabled: ENV?.KALTURA_ENABLED || false

    _attachEditorToDescription: =>
      @$description.editorBox()
      $('.rte_switch_views_link').click preventDefault => @$description.editorBox('toggle')

    _attachDatepickerToDateFields: =>
      if @assignment.isSimple()
        @$dueAt.datetime_field()
      @$unlockAt.datetime_field()
      @$lockAt.datetime_field()

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
      unless ENV?.IS_MOOC
        data = @groupCategorySelector.filterFormData data
      # should update the date fields.. pretty hacky.
      if @showingAdvancedOptions()
        @dueDateOverrideView.updateOverrides()
        defaultDates = @dueDateOverrideView.getDefaultDueDate()
        data.lock_at = defaultDates?.get('lock_at') or null
        data.unlock_at = defaultDates?.get('unlock_at') or null
        data.due_at = defaultDates?.get('due_at') or null
      return data

    submit: (event) =>
      event.preventDefault()
      event.stopPropagation()
      if @dueDateOverrideView.containsSectionsWithoutOverrides()
        sections = @dueDateOverrideView.sectionsWithoutOverrides()
        missingDateDialog = new MissingDateDialog
          validationFn: -> sections
          labelFn: ( section ) -> section.get 'name'
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
        assignmentData.submission_types = [ 'not_graded' ]
      else if assignmentData.submission_type == 'online'
        types = _.select _.keys(assignmentData.online_submission_types), (k) ->
          assignmentData.online_submission_types[k]
        assignmentData.submission_types = types
      else
        assignmentData.submission_types = [ assignmentData.submission_type ]
      delete assignmentData.online_submission_type
      delete assignmentData.online_submission_types
      assignmentData

    _filterAllowedExtensions: (data) =>
      restrictFileExtensions = data.restrict_file_extensions
      delete data.restrict_file_extensions
      if restrictFileExtensions
        data.allowed_extensions = _.select data.allowed_extensions.split(","), (ext) ->
          $.trim(ext.toString()).length > 0
      else
        data.allowed_extensions = null
      data

    # -- Pre-Save Validations --

    fieldSelectors:
      assignmentToggleAdvancedOptions: '#assignment_toggle_advanced_options'

    validateBeforeSave: (data, errors) =>
      errors = @_validateTitle data, errors
      errors = @_validateSubmissionTypes data, errors
      errors = @_validateAllowedExtensions data, errors
      unless ENV?.IS_MOOC
        errors = @groupCategorySelector.validateBeforeSave(data, errors)
      errors = @_validateAdvancedOptions(data, errors)
      errors

    _validateTitle: (data, errors) =>
      if !data.name or $.trim(data.name.toString()).length == 0
        errors["'name'"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      errors


    _validateSubmissionTypes: (data, errors) =>
      if data.submission_type == 'online' and data.submission_types.length == 0
        errors["'online_submission_types[online_text_entry]'"] = [
          message: I18n.t 'at_least_one_submission_type', 'Please choose at least one submission type'
        ]
      errors

    _validateAllowedExtensions: (data, errors) =>
      if data.allowed_extensions && data.allowed_extensions.length == 0
        errors["'allowed_extensions'"] = [
          message: I18n.t 'at_least_one_file_type', 'Please specify at least one allowed file type'
        ]
      errors

    # add an extra error box if errors are hidden
    _validateAdvancedOptions: (data, errors) =>
      ariaExpanded = @$advancedAssignmentOptions.attr('aria-expanded')
      expanded = ariaExpanded == 'true' or ariaExpanded == true
      if _.keys(errors).length > 0 && !expanded
        errors["assignmentToggleAdvancedOptions"] = [
          message: I18n.t 'advanced_options_errors', 'There were errors on one or more advanced options'
        ]
      errors

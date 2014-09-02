define [
  'INST'
  'i18n!assignment'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jquery'
  'wikiSidebar'
  'jst/assignments/EditView'
  'compiled/userSettings'
  'compiled/models/TurnitinSettings'
  'compiled/views/assignments/TurnitinSettingsDialog'
  'compiled/fn/preventDefault'
  'compiled/views/calendar/MissingDateDialogView'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/jquery/toggleAccessibly'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jqueryui/dialog'
  'jquery.toJSON'
  'compiled/jquery.rails_flash_notifications'
], (INST, I18n, ValidatedFormView, _, $, wikiSidebar, template,
userSettings, TurnitinSettings, TurnitinSettingsDialog, preventDefault, MissingDateDialog,
AssignmentGroupSelector, GroupCategorySelector, toggleAccessibly) ->

  class EditView extends ValidatedFormView

    template: template

    dontRenableAfterSaveSuccess: true

    ASSIGNMENT_GROUP_SELECTOR = '#assignment_group_selector'
    DESCRIPTION = '[name="description"]'
    SUBMISSION_TYPE = '[name="submission_type"]'
    ONLINE_SUBMISSION_TYPES = '#assignment_online_submission_types'
    NAME = '[name="name"]'
    ALLOW_FILE_UPLOADS = '#assignment_online_upload'
    RESTRICT_FILE_UPLOADS = '#assignment_restrict_file_extensions'
    RESTRICT_FILE_UPLOADS_OPTIONS = '#restrict_file_extensions_container'
    ALLOWED_EXTENSIONS = '#allowed_extensions_container'
    TURNITIN_ENABLED = '#assignment_turnitin_enabled'
    ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
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
      els["#{DESCRIPTION}"] = '$description'
      els["#{SUBMISSION_TYPE}"] = '$submissionType'
      els["#{ONLINE_SUBMISSION_TYPES}"] = '$onlineSubmissionTypes'
      els["#{NAME}"] = '$name'
      els["#{ALLOW_FILE_UPLOADS}"] = '$allowFileUploads'
      els["#{RESTRICT_FILE_UPLOADS}"] = '$restrictFileUploads'
      els["#{RESTRICT_FILE_UPLOADS_OPTIONS}"] = '$restrictFileUploadsOptions'
      els["#{ALLOWED_EXTENSIONS}"] = '$allowedExtensions'
      els["#{TURNITIN_ENABLED}"] = '$turnitinEnabled'
      els["#{ADVANCED_TURNITIN_SETTINGS}"] = '$advancedTurnitinSettings'
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
      @setDefaultsIfNew()
      @dueDateOverrideView = options.views['js-assignment-overrides']
      @model.on 'sync', -> window.location = @get 'html_url'
      @gradingTypeSelector.on 'change:gradingType', @handleGradingTypeChange

    handleCancel: (ev) =>
      ev.preventDefault()
      window.location = ENV.CANCEL_TO if ENV.CANCEL_TO?

    settingsToCache:() =>
      ["assignment_group_id","grading_type","submission_type","submission_types",
       "points_possible","allowed_extensions","peer_reviews","peer_review_count",
       "automatic_peer_reviews","group_category_id","grade_group_students_individually",
       "turnitin_enabled"]

    setDefaultsIfNew: =>
      if @assignment.isNew()
        if userSettings.contextGet('new_assignment_settings')
          _.each(@settingsToCache(), (setting) =>
            setting_from_cache = userSettings.contextGet('new_assignment_settings')[setting]
            if setting_from_cache == "1" || setting_from_cache == "0"
              setting_from_cache = parseInt setting_from_cache
            if setting_from_cache && (!@assignment.get(setting) || @assignment.get(setting)?.length == 0)
              @assignment.set(setting, setting_from_cache)
          )
        else
          @assignment.set('submission_type','online')
          @assignment.set('submission_types',['online'])

    cacheAssignmentSettings: =>
      new_assignment_settings = _.pick(@getFormData(), @settingsToCache()...)
      userSettings.contextSet('new_assignment_settings', new_assignment_settings)

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
      @_attachEditorToDescription()
      $ @_initializeWikiSidebar
      this

    toJSON: =>
      data = @assignment.toView()
      _.extend data,
        kalturaEnabled: ENV?.KALTURA_ENABLED or false
        postToSISEnabled: ENV?.POST_TO_SIS or false
        isLargeRoster: ENV?.IS_LARGE_ROSTER or false
        differentiatedAssignmnetsEnabled: ENV?.DIFFERENTIATED_ASSIGNMENTS_ENABLED or false
        submissionTypesFrozen: _.include(data.frozenAttributes, 'submission_types')

    _attachEditorToDescription: =>
      @$description.editorBox()
      $('.rte_switch_views_link').click (e) =>
        e.preventDefault()
        @$description.editorBox 'toggle'
        # hide the clicked link, and show the other toggle link.
        $(e.currentTarget).siblings('.rte_switch_views_link').andSelf().toggle()

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
      unless data.post_to_sis
        data.post_to_sis = false
      @dueDateOverrideView.updateOverrides()
      defaultDates = @dueDateOverrideView.getDefaultDueDate()
      data.lock_at = defaultDates?.get('lock_at') or null
      data.unlock_at = defaultDates?.get('unlock_at') or null
      data.due_at = defaultDates?.get('due_at') or null
      if ENV?.DIFFERENTIATED_ASSIGNMENTS_ENABLED
        data.only_visible_to_overrides = @dueDateOverrideView.containsSectionsWithoutOverrides()
      data.assignment_overrides = @dueDateOverrideView.getOverrides()
      return data

    submit: (event) =>
      event.preventDefault()
      event.stopPropagation()

      @cacheAssignmentSettings()

      @dueDateOverrideView.updateOverrides()
      if @dueDateOverrideView.containsSectionsWithoutOverrides()
        sections = @dueDateOverrideView.sectionsWithoutOverrides()
        missingDateDialog = new MissingDateDialog
          validationFn: -> sections
          labelFn: (section) -> section.get 'name'
          success: =>
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

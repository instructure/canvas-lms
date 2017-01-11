define [
  'INST'
  'i18n!assignment'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jquery'
  'jsx/shared/rce/RichContentEditor'
  'jst/assignments/EditView'
  'compiled/userSettings'
  'compiled/models/TurnitinSettings'
  'compiled/models/VeriCiteSettings'
  'compiled/views/assignments/TurnitinSettingsDialog'
  'compiled/fn/preventDefault'
  'compiled/views/calendar/MissingDateDialogView'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/jquery/toggleAccessibly'
  'compiled/views/editor/KeyboardShortcuts'
  'jsx/shared/conditional_release/ConditionalRelease'
  'compiled/util/deparam'
  'jsx/assignments/AssignmentConfigurationTools'
  'jqueryui/dialog'
  'jquery.toJSON'
  'compiled/jquery.rails_flash_notifications'
  'compiled/behaviors/tooltip'
], (INST, I18n, ValidatedFormView, _, $, RichContentEditor, EditViewTemplate,
  userSettings, TurnitinSettings, VeriCiteSettings, TurnitinSettingsDialog,
  preventDefault, MissingDateDialog, AssignmentGroupSelector,
  GroupCategorySelector, toggleAccessibly, RCEKeyboardShortcuts,
  ConditionalRelease, deparam, SimilarityDetectionTools) ->

  RichContentEditor.preloadRemoteModule()

  class EditView extends ValidatedFormView

    template: EditViewTemplate

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
    VERICITE_ENABLED = '#assignment_vericite_enabled'
    ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
    GRADING_TYPE_SELECTOR = '#grading_type_selector'
    GRADED_ASSIGNMENT_FIELDS = '#graded_assignment_fields'
    EXTERNAL_TOOL_SETTINGS = '#assignment_external_tool_settings'
    GROUP_CATEGORY_SELECTOR = '#group_category_selector'
    PEER_REVIEWS_FIELDS = '#assignment_peer_reviews_fields'
    EXTERNAL_TOOLS_URL = '#assignment_external_tool_tag_attributes_url'
    EXTERNAL_TOOLS_CONTENT_TYPE = '#assignment_external_tool_tag_attributes_content_type'
    EXTERNAL_TOOLS_CONTENT_ID = '#assignment_external_tool_tag_attributes_content_id'
    EXTERNAL_TOOLS_NEW_TAB = '#assignment_external_tool_tag_attributes_new_tab'
    ASSIGNMENT_POINTS_POSSIBLE = '#assignment_points_possible'
    ASSIGNMENT_POINTS_CHANGE_WARN = '#point_change_warning'
    SECURE_PARAMS = '#secure_params'

    PEER_REVIEWS_BOX = '#assignment_peer_reviews'
    INTRA_GROUP_PEER_REVIEWS = '#intra_group_peer_reviews_toggle'
    GROUP_CATEGORY_BOX = '#has_group_category'
    MODERATED_GRADING_BOX = '#assignment_moderated_grading'
    CONDITIONAL_RELEASE_TARGET = '#conditional_release_target'
    SIMILARITY_DETECTION_TOOLS = '#similarity_detection_tools'

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
      els["#{VERICITE_ENABLED}"] = '$vericiteEnabled'
      els["#{ADVANCED_TURNITIN_SETTINGS}"] = '$advancedTurnitinSettings'
      els["#{GRADING_TYPE_SELECTOR}"] = '$gradingTypeSelector'
      els["#{GRADED_ASSIGNMENT_FIELDS}"] = '$gradedAssignmentFields'
      els["#{EXTERNAL_TOOL_SETTINGS}"] = '$externalToolSettings'
      els["#{GROUP_CATEGORY_SELECTOR}"] = '$groupCategorySelector'
      els["#{PEER_REVIEWS_FIELDS}"] = '$peerReviewsFields'
      els["#{EXTERNAL_TOOLS_URL}"] = '$externalToolsUrl'
      els["#{EXTERNAL_TOOLS_NEW_TAB}"] = '$externalToolsNewTab'
      els["#{EXTERNAL_TOOLS_CONTENT_TYPE}"] = '$externalToolsContentType'
      els["#{EXTERNAL_TOOLS_CONTENT_ID}"] = '$externalToolsContentId'
      els["#{ASSIGNMENT_POINTS_POSSIBLE}"] = '$assignmentPointsPossible'
      els["#{ASSIGNMENT_POINTS_CHANGE_WARN}"] = '$pointsChangeWarning'
      els["#{MODERATED_GRADING_BOX}"] = '$moderatedGradingBox'
      els["#{CONDITIONAL_RELEASE_TARGET}"] = '$conditionalReleaseTarget'
      els["#{SIMILARITY_DETECTION_TOOLS}"] = '$similarityDetectionTools'
      els["#{SECURE_PARAMS}"] = '$secureParams'
      els
    )

    events: _.extend({}, @::events, do ->
      events = {}
      events["click .cancel_button"] = 'handleCancel'
      events["click .save_and_publish"] = 'saveAndPublish'
      events["change #{SUBMISSION_TYPE}"] = 'handleSubmissionTypeChange'
      events["change #{ONLINE_SUBMISSION_TYPES}"] = 'handleOnlineSubmissionTypeChange'
      events["change #{RESTRICT_FILE_UPLOADS}"] = 'handleRestrictFileUploadsChange'
      events["click #{ADVANCED_TURNITIN_SETTINGS}"] = 'showTurnitinDialog'
      events["change #{TURNITIN_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
      events["change #{VERICITE_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
      events["change #{ALLOW_FILE_UPLOADS}"] = 'toggleRestrictFileUploads'
      events["click #{EXTERNAL_TOOLS_URL}_find"] = 'showExternalToolsDialog'
      events["change #assignment_points_possible"] = 'handlePointsChange'
      events["change #{PEER_REVIEWS_BOX}"] = 'handleModeratedGradingChange'
      events["change #{MODERATED_GRADING_BOX}"] = 'handleModeratedGradingChange'
      events["change #{GROUP_CATEGORY_BOX}"] = 'handleGroupCategoryChange'
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        events["change"] = 'onChange'
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
      @on 'success', @redirectAfterSave
      @gradingTypeSelector.on 'change:gradingType', @handleGradingTypeChange
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @gradingTypeSelector.on 'change:gradingType', @onChange

    handleCancel: (ev) =>
      ev.preventDefault()
      @redirectAfterCancel()

    settingsToCache:() =>
      ["assignment_group_id","grading_type","submission_type","submission_types",
       "points_possible","allowed_extensions","peer_reviews","peer_review_count",
       "automatic_peer_reviews","group_category_id","grade_group_students_individually",
       "turnitin_enabled", "vericite_enabled"]

    handlePointsChange:(ev) =>
      ev.preventDefault()
      if @assignment.hasSubmittedSubmissions()
        @$pointsChangeWarning.toggleAccessibly(@$assignmentPointsPossible.val() != "#{@assignment.pointsPossible()}")

    checkboxAccessibleAdvisory: (box) ->
      label = box.parent()
      advisory = label.find('span.screenreader-only.accessible_label')
      advisory = $('<span class="screenreader-only accessible_label"></span>').appendTo(label) unless advisory.length
      advisory

    setImplicitCheckboxValue: (box, value) ->
      $("input[type='hidden'][name='#{box.attr('name')}']", box.parent()).attr('value', value)

    disableCheckbox: (box, message) ->
      box.prop("disabled", true).parent().attr('data-tooltip', 'top').data('tooltip', {disabled: false}).attr('title', message)
      @setImplicitCheckboxValue(box, if box.prop('checked') then '1' else '0')
      @checkboxAccessibleAdvisory(box).text(message)

    enableCheckbox: (box) ->
      if box.prop('disabled')
        return if @assignment.inClosedGradingPeriod()

        box.prop('disabled', false).parent().timeoutTooltip().timeoutTooltip('disable').removeAttr('data-tooltip').removeAttr('title')
        @setImplicitCheckboxValue(box, '0')
        @checkboxAccessibleAdvisory(box).text('')

    handleGroupCategoryChange: ->
      isGrouped = @$groupCategoryBox.prop('checked')
      @$intraGroupPeerReviews.toggleAccessibly(isGrouped)
      @handleModeratedGradingChange()

    handleModeratedGradingChange: =>
      if !ENV?.HAS_GRADED_SUBMISSIONS
        if @$moderatedGradingBox.prop('checked')
          @disableCheckbox(@$peerReviewsBox, I18n.t("Peer reviews cannot be enabled for moderated assignments"))
          @disableCheckbox(@$groupCategoryBox, I18n.t("Group assignments cannot be enabled for moderated assignments"))
          @enableCheckbox(@$moderatedGradingBox)
        else
          if @$groupCategoryBox.prop('checked')
            @disableCheckbox(@$moderatedGradingBox,  I18n.t("Moderated grading cannot be enabled for group assignments"))
          else if @$peerReviewsBox.prop('checked')
            @disableCheckbox(@$moderatedGradingBox, I18n.t("Moderated grading cannot be enabled for peer reviewed assignments"))
          else
            @enableCheckbox(@$moderatedGradingBox)

          @enableCheckbox(@$peerReviewsBox)
          @enableCheckbox(@$groupCategoryBox)

    setDefaultsIfNew: =>
      if @assignment.isNew()
        if userSettings.contextGet('new_assignment_settings')
          _.each(@settingsToCache(), (setting) =>
            setting_from_cache = userSettings.contextGet('new_assignment_settings')[setting]
            if setting_from_cache == "1" || setting_from_cache == "0"
              setting_from_cache = parseInt setting_from_cache
            if setting_from_cache && (!@assignment.get(setting)? || @assignment.get(setting)?.length == 0)
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
      type = "turnitin"
      model = @assignment.get('turnitin_settings')
      if @$vericiteEnabled.prop('checked')
        type = "vericite"
        model = @assignment.get('vericite_settings')
      turnitinDialog = new TurnitinSettingsDialog(model, type)
      turnitinDialog.render().on 'settings:change', (settings) =>
        if @$vericiteEnabled.prop('checked')
          @assignment.set 'vericite_settings', new VeriCiteSettings(settings)
        else
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
          @$externalToolsContentType.val(data['item[type]'])
          @$externalToolsContentId.val(data['item[id]'])
          @$externalToolsUrl.val(data['item[url]'])
          @$externalToolsNewTab.prop('checked', data['item[new_tab]'] == '1')

    toggleRestrictFileUploads: =>
      @$restrictFileUploadsOptions.toggleAccessibly @$allowFileUploads.prop('checked')

    toggleAdvancedTurnitinSettings: (ev) =>
      ev.preventDefault()
      @$advancedTurnitinSettings.toggleAccessibly (@$turnitinEnabled.prop('checked') || @$vericiteEnabled.prop('checked'))

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
      @$similarityDetectionTools.toggleAccessibly subVal == 'online' && ENV.PLAGIARISM_DETECTION_PLATFORM
      if subVal == 'online'
        @handleOnlineSubmissionTypeChange()

    handleOnlineSubmissionTypeChange: (env) =>
      showConfigTools = @$onlineSubmissionTypes.find(ALLOW_FILE_UPLOADS).attr('checked')
      @$similarityDetectionTools.toggleAccessibly showConfigTools && ENV.PLAGIARISM_DETECTION_PLATFORM

    afterRender: =>
      # have to do these here because they're rendered by other things
      @$peerReviewsBox = $("#{PEER_REVIEWS_BOX}")
      @$intraGroupPeerReviews = $("#{INTRA_GROUP_PEER_REVIEWS}")
      @$groupCategoryBox = $("#{GROUP_CATEGORY_BOX}")

      @similarityDetectionTools = SimilarityDetectionTools.attach(
            @$similarityDetectionTools.get(0),
            parseInt(ENV.COURSE_ID),
            @$secureParams.val(),
            parseInt(ENV.SELECTED_CONFIG_TOOL_ID),
            ENV.SELECTED_CONFIG_TOOL_TYPE)

      @_attachEditorToDescription()
      @addTinyMCEKeyboardShortcuts()
      @handleModeratedGradingChange()
      @handleOnlineSubmissionTypeChange()
      @handleSubmissionTypeChange()

      if ENV?.HAS_GRADED_SUBMISSIONS
        @disableCheckbox(@$moderatedGradingBox, I18n.t("Moderated grading setting cannot be changed if graded submissions exist"))
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @conditionalReleaseEditor = ConditionalRelease.attach(
          @$conditionalReleaseTarget.get(0),
          I18n.t('assignment'),
          ENV.CONDITIONAL_RELEASE_ENV)

      @disableFields() if @assignment.inClosedGradingPeriod()

      this

    toJSON: =>
      data = @assignment.toView()
      _.extend data,
        kalturaEnabled: ENV?.KALTURA_ENABLED or false
        postToSISEnabled: ENV?.POST_TO_SIS or false
        isLargeRoster: ENV?.IS_LARGE_ROSTER or false
        submissionTypesFrozen: _.include(data.frozenAttributes, 'submission_types')
        conditionalReleaseServiceEnabled: ENV?.CONDITIONAL_RELEASE_SERVICE_ENABLED or false


    _attachEditorToDescription: =>
      RichContentEditor.initSidebar()
      RichContentEditor.loadNewEditor(@$description, { focus: true, manageParent: true })

      $('.rte_switch_views_link').click (e) =>
        e.preventDefault()
        RichContentEditor.callOnRCE(@$description, 'toggle')
        # hide the clicked link, and show the other toggle link.
        $(e.currentTarget).siblings('.rte_switch_views_link').andSelf().toggle()

    addTinyMCEKeyboardShortcuts: =>
      keyboardShortcutsView = new RCEKeyboardShortcuts()
      keyboardShortcutsView.render().$el.insertBefore($(".rte_switch_views_link:first"))

    # -- Data for Submitting --
    getFormData: =>
      data = super
      data = @_inferSubmissionTypes data
      data = @_filterAllowedExtensions data
      data = @_unsetGroupsIfExternalTool data
      unless ENV?.IS_LARGE_ROSTER
        data = @groupCategorySelector.filterFormData data
      # should update the date fields.. pretty hacky.
      unless data.post_to_sis
        data.post_to_sis = false
      defaultDates = @dueDateOverrideView.getDefaultDueDate()
      data.lock_at = defaultDates?.get('lock_at') or null
      data.unlock_at = defaultDates?.get('unlock_at') or null
      data.due_at = defaultDates?.get('due_at') or null
      data.only_visible_to_overrides = !@dueDateOverrideView.overridesContainDefault()
      data.assignment_overrides = @dueDateOverrideView.getOverrides()
      data.published = true if @shouldPublish
      return data

    saveFormData: =>
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        super.pipe (data, status, xhr) =>
          @conditionalReleaseEditor.updateAssignment(data)
          # Restore expected promise values
          @conditionalReleaseEditor.save().pipe(
            => new $.Deferred().resolve(data, status, xhr).promise()
            (err) => new $.Deferred().reject(xhr, err).promise())
      else
        super

    submit: (event) =>
      event.preventDefault()
      event.stopPropagation()

      @cacheAssignmentSettings()

      if @dueDateOverrideView.containsSectionsWithoutOverrides()
        sections = @dueDateOverrideView.sectionsWithoutOverrides()
        missingDateDialog = new MissingDateDialog
          validationFn: -> sections
          labelFn: (section) -> section.get 'name'
          success: (dateDialog) =>
            dateDialog.dialog('close').remove()
            ValidatedFormView::submit.call(this)
        missingDateDialog.cancel = (e) ->
          missingDateDialog.$dialog.dialog('close').remove()

        missingDateDialog.render()
      else
        super

    saveAndPublish: (event) ->
      @shouldPublish = true
      @disableWhileLoadingOpts = {buttons: ['.save_and_publish']}
      @submit(event)

    onSaveFail: (xhr) =>
      @shouldPublish = false
      @disableWhileLoadingOpts = {}
      super(xhr)

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

    _unsetGroupsIfExternalTool: (data) =>
      if data.submission_type == 'external_tool'
        data.group_category_id = null
      data

    # -- Pre-Save Validations --

    fieldSelectors: _.extend(
      AssignmentGroupSelector::fieldSelectors,
      GroupCategorySelector::fieldSelectors
    )

    showErrors: (errors) ->
      # override view handles displaying override errors, remove them
      # before calling super
      delete errors.assignmentOverrides
      super(errors)
      @trigger 'show-errors', errors
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        if errors['conditional_release']
          @conditionalReleaseEditor.focusOnError()

    validateBeforeSave: (data, errors) =>
      errors = @_validateTitle data, errors
      errors = @_validateSubmissionTypes data, errors
      errors = @_validateAllowedExtensions data, errors
      errors = @assignmentGroupSelector.validateBeforeSave(data, errors)
      unless ENV?.IS_LARGE_ROSTER
        errors = @groupCategorySelector.validateBeforeSave(data, errors)
      errors = @_validatePointsPossible(data, errors)
      errors = @_validatePointsRequired(data, errors)
      errors = @_validateExternalTool(data, errors)
      data2 =
        assignment_overrides: @dueDateOverrideView.getAllDates()
      errors = @dueDateOverrideView.validateBeforeSave(data2,errors)
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        crErrors = @conditionalReleaseEditor.validateBeforeSave()
        errors['conditional_release'] = crErrors if crErrors
      errors

    _validateTitle: (data, errors) =>
      return errors if _.contains(@model.frozenAttributes(), "title")

      if !data.name or $.trim(data.name.toString()).length == 0
        errors["name"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      else if $.trim(data.name.toString()).length > 255
        errors["name"] = [
          message: I18n.t 'name_too_long', 'Name is too long'
        ]
      errors

    _validateSubmissionTypes: (data, errors) =>
      if data.submission_type == 'online' and data.submission_types.length == 0
        errors["online_submission_types[online_text_entry]"] = [
          message: I18n.t 'at_least_one_submission_type', 'Please choose at least one submission type'
        ]
      else if data.submission_type == 'online' and data.vericite_enabled == "1"
        allow_vericite = true
        _.select _.keys(data.submission_types), (k) ->
          allow_vericite = allow_vericite && (data.submission_types[k] == "online_upload" || data.submission_types[k] == "online_text_entry")
        if !allow_vericite
          errors["online_submission_types[online_text_entry]"] = [
            message: I18n.t 'vericite_submission_types_validation', 'VeriCite only supports file submissions and text entry'
          ]

      errors

    _validateAllowedExtensions: (data, errors) =>
      if (data.allowed_extensions and _.contains(data.submission_types, "online_upload")) and data.allowed_extensions.length == 0
        errors["allowed_extensions"] = [
          message: I18n.t 'at_least_one_file_type', 'Please specify at least one allowed file type'
        ]
      errors

    _validatePointsPossible: (data, errors) =>
      return errors if _.contains(@model.frozenAttributes(), "points_possible")

      if data.points_possible and isNaN(parseFloat(data.points_possible))
        errors["points_possible"] = [
          message: I18n.t 'points_possible_number', 'Points possible must be a number'
        ]
      errors

    # Require points possible > 0
    # if grading type === percent || letter_grade || gpa_scale
    _validatePointsRequired: (data, errors) =>
      return errors unless _.include ['percent','letter_grade','gpa_scale'], data.grading_type

      if parseInt(data.points_possible,10) < 0 or isNaN(parseFloat(data.points_possible))
        errors["points_possible"] = [
          message: I18n.t("Points possible must be 0 or more for selected grading type")
        ]
      errors

    _validateExternalTool: (data, errors) =>
      if data.submission_type == 'external_tool' and $.trim(data.external_tool_tag_attributes?.url?.toString()).length == 0
        errors["external_tool_tag_attributes[url]"] = [
          message: I18n.t 'External Tool URL cannot be left blank'
        ]
      errors

    redirectAfterSave: ->
      window.location = @locationAfterSave(deparam())

    locationAfterSave: (params) ->
      return params['return_to'] if params['return_to']?
      @model.get 'html_url'

    redirectAfterCancel: ->
      location = @locationAfterCancel(deparam())
      window.location = location if location

    locationAfterCancel: (params) ->
      return params['return_to'] if params['return_to']?
      return ENV.CANCEL_TO if ENV.CANCEL_TO?
      null

    onChange: ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && @assignmentUpToDate
        @assignmentUpToDate = false

    updateConditionalRelease: ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !@assignmentUpToDate
        assignmentData = @getFormData()
        @conditionalReleaseEditor.updateAssignment(assignmentData)
        @assignmentUpToDate = true

    disableFields: ->
      ignoreFields = [
        "#overrides-wrapper *"
        "#submission_type_fields *"
        "#assignment_peer_reviews_fields *"
        "#assignment_description"
        "#assignment_notify_of_update"
        "#assignment_post_to_sis"
      ]
      ignoreFilter = ignoreFields.map((field) -> "not(#{field})").join(":")

      self = this
      @$el.find(":checkbox:#{ignoreFilter}").each ->
        self.disableCheckbox($(this), I18n.t("Cannot be edited for assignments in closed grading periods"))
      @$el.find(":radio:#{ignoreFilter}").click(@ignoreClickHandler)
      @$el.find("select:#{ignoreFilter}").each(@lockSelectValueHandler)

    ignoreClickHandler: (event) ->
      event.preventDefault()
      event.stopPropagation()

    lockSelectValueHandler: ->
      lockedValue = this.value
      $(this).change (event) ->
        this.value = lockedValue
        event.stopPropagation()

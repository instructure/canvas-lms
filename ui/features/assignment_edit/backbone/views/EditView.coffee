#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import ReactDOM from 'react-dom'
import INST from 'browser-sniffer'
import {useScope as useI18nScope} from '@canvas/i18n'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView.coffee'
import _ from 'underscore'
import $, {param} from 'jquery'
import pluralize from 'str-pluralize'
import numberHelper from '@canvas/i18n/numberHelper'
import round from 'round'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import { showFlashAlert } from '@canvas/alerts/react/FlashAlert'
import EditViewTemplate from '../../jst/EditView.handlebars'
import userSettings from '@canvas/user-settings'
import TurnitinSettings from '@canvas/assignments/TurnitinSettings.coffee'
import VeriCiteSettings from '@canvas/assignments/VeriCiteSettings.coffee'
import File from '@canvas/files/backbone/models/File.coffee'
import TurnitinSettingsDialog from './TurnitinSettingsDialog.coffee'
import MissingDateDialog from '@canvas/due-dates/backbone/views/MissingDateDialogView.coffee'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector.coffee'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector.coffee'
import toggleAccessibly from '@canvas/assignments/jquery/toggleAccessibly'
import ConditionalRelease from '@canvas/conditional-release-editor'
import deparam from 'deparam'
import SisValidationHelper from '@canvas/sis/SisValidationHelper'
import SimilarityDetectionTools from '../../react/AssignmentConfigurationTools'
import ModeratedGradingFormFieldGroup from '../../react/ModeratedGradingFormFieldGroup'
import AllowedAttemptsWithState from '../../react/allowed_attempts/AllowedAttemptsWithState'
import DefaultToolForm from '../../react/DefaultToolForm'
import UsageRightsSelectBox from '@canvas/files/react/components/UsageRightsSelectBox'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import * as returnToHelper from '@canvas/util/validateReturnToURL'
import setUsageRights from '@canvas/files/util/setUsageRights'
import 'jqueryui/dialog'
import '@canvas/util/toJSON'
import '@canvas/rails-flash-notifications'
import '../../../../boot/initializers/activateTooltips.js'
import {AnnotatedDocumentSelector} from '../../react/EditAssignment'

I18n = useI18nScope('assignment_editview')

###
xsslint safeString.identifier srOnly
###

RichContentEditor.preloadRemoteModule()

export default class EditView extends ValidatedFormView

  template: EditViewTemplate

  dontRenableAfterSaveSuccess: true

  ASSIGNMENT_GROUP_SELECTOR = '#assignment_group_selector'
  DESCRIPTION = '[name="description"]'
  SUBMISSION_TYPE = '[name="submission_type"]'
  ONLINE_SUBMISSION_TYPES = '#assignment_online_submission_types'
  NAME = '[name="name"]'
  ALLOW_FILE_UPLOADS = '#assignment_online_upload'
  ALLOW_ANNOTATED_DOCUMENT = '#assignment_annotated_document'
  ALLOW_ANNOTATED_DOCUMENT_INFO = '#assignment_annotated_document_info'
  ALLOW_TEXT_ENTRY = '#assignment_text_entry'
  RESTRICT_FILE_UPLOADS = '#assignment_restrict_file_extensions'
  RESTRICT_FILE_UPLOADS_OPTIONS = '#restrict_file_extensions_container'
  ANNOTATED_DOCUMENT_OPTIONS = '#annotated_document_chooser_container'
  ALLOWED_EXTENSIONS = '#allowed_extensions_container'
  TURNITIN_ENABLED = '#assignment_turnitin_enabled'
  VERICITE_ENABLED = '#assignment_vericite_enabled'
  ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
  GRADING_TYPE_SELECTOR = '#grading_type_selector'
  GRADED_ASSIGNMENT_FIELDS = '#graded_assignment_fields'
  EXTERNAL_TOOL_SETTINGS = '#assignment_external_tool_settings'
  EXTERNAL_TOOL_SETTINGS_NEW_TAB = '#external_tool_new_tab_container'
  DEFAULT_EXTERNAL_TOOL_CONTAINER = '#default_external_tool_container'
  EXTERNAL_TOOL_PLACEMENT_LAUNCH_CONTAINER = '#assignment_submission_type_selection_tool_launch_container'
  EXTERNAL_TOOL_PLACEMENT_LAUNCH_BUTTON = '#assignment_submission_type_selection_launch_button'
  EXTERNAL_TOOL_PLACEMENT_LAUNCH_BUTTON_TEXT = '#assignment_submission_type_selection_launch_button_text'
  EXTERNAL_TOOL_DATA = '#assignment_submission_type_external_data'
  ALLOWED_ATTEMPTS_CONTAINER = '#allowed_attempts_fields'
  GROUP_CATEGORY_SELECTOR = '#group_category_selector'
  PEER_REVIEWS_FIELDS = '#assignment_peer_reviews_fields'
  EXTERNAL_TOOLS_URL = '#assignment_external_tool_tag_attributes_url'
  EXTERNAL_TOOLS_CONTENT_TYPE = '#assignment_external_tool_tag_attributes_content_type'
  EXTERNAL_TOOLS_CONTENT_ID = '#assignment_external_tool_tag_attributes_content_id'
  EXTERNAL_TOOLS_NEW_TAB = '#assignment_external_tool_tag_attributes_new_tab'
  EXTERNAL_TOOLS_IFRAME_WIDTH = '#assignment_external_tool_tag_attributes_iframe_width'
  EXTERNAL_TOOLS_IFRAME_HEIGHT = '#assignment_external_tool_tag_attributes_iframe_height'
  EXTERNAL_TOOLS_CUSTOM_PARAMS = '#assignment_external_tool_tag_attributes_custom_params'
  ASSIGNMENT_POINTS_POSSIBLE = '#assignment_points_possible'
  ASSIGNMENT_POINTS_CHANGE_WARN = '#point_change_warning'
  SECURE_PARAMS = '#secure_params'

  PEER_REVIEWS_BOX = '#assignment_peer_reviews'
  INTRA_GROUP_PEER_REVIEWS = '#intra_group_peer_reviews_toggle'
  GROUP_CATEGORY_BOX = '#has_group_category'
  CONDITIONAL_RELEASE_TARGET = '#conditional_release_target'
  SIMILARITY_DETECTION_TOOLS = '#similarity_detection_tools'
  ANONYMOUS_GRADING_BOX = '#assignment_anonymous_grading'
  ASSIGNMENT_EXTERNAL_TOOLS = '#assignment_external_tools'
  USAGE_RIGHTS_CONTAINER = '#annotated_document_usage_rights_container'
  USAGE_RIGHTS_SELECTOR = '#usageRightSelector'
  COPYRIGHT_HOLDER = '#copyrightHolder'
  CREATIVE_COMMONS_SELECTION = '#creativeCommonsSelection'

  LTI_EXT_MASTERY_CONNECT = 'https://canvas.instructure.com/lti/mastery_connect_assessment'

  els: _.extend({}, @::els, do ->
    els = {}
    els["#{ASSIGNMENT_GROUP_SELECTOR}"] = '$assignmentGroupSelector'
    els["#{DESCRIPTION}"] = '$description'
    els["#{SUBMISSION_TYPE}"] = '$submissionType'
    els["#{ONLINE_SUBMISSION_TYPES}"] = '$onlineSubmissionTypes'
    els["#{NAME}"] = '$name'
    els["#{ALLOW_FILE_UPLOADS}"] = '$allowFileUploads'
    els["#{ALLOW_ANNOTATED_DOCUMENT}"] = '$allowAnnotatedDocument'
    els["#{ALLOW_ANNOTATED_DOCUMENT_INFO}"] = '$allowAnnotatedDocumentInfo'
    els["#{RESTRICT_FILE_UPLOADS}"] = '$restrictFileUploads'
    els["#{RESTRICT_FILE_UPLOADS_OPTIONS}"] = '$restrictFileUploadsOptions'
    els["#{ANNOTATED_DOCUMENT_OPTIONS}"] = '$annotatedDocumentOptions'
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
    els["#{EXTERNAL_TOOLS_IFRAME_WIDTH}"] = '$externalToolsIframeWidth'
    els["#{EXTERNAL_TOOLS_IFRAME_HEIGHT}"] = '$externalToolsIframeHeight'
    els["#{EXTERNAL_TOOLS_CONTENT_TYPE}"] = '$externalToolsContentType'
    els["#{EXTERNAL_TOOLS_CUSTOM_PARAMS}"] = '$externalToolsCustomParams'
    els["#{EXTERNAL_TOOLS_CONTENT_ID}"] = '$externalToolsContentId'
    els["#{EXTERNAL_TOOL_DATA}"] = '$externalToolExternalData'
    els["#{EXTERNAL_TOOL_SETTINGS_NEW_TAB}"] = '$externalToolNewTabContainer'
    els["#{DEFAULT_EXTERNAL_TOOL_CONTAINER}"] = '$defaultExternalToolContainer'
    els["#{EXTERNAL_TOOL_PLACEMENT_LAUNCH_CONTAINER}"] = '$externalToolPlacementLaunchContainer'
    els["#{EXTERNAL_TOOL_PLACEMENT_LAUNCH_BUTTON}"] = '$externalToolPlacementLaunchButton'
    els["#{EXTERNAL_TOOL_PLACEMENT_LAUNCH_BUTTON_TEXT}"] = '$externalToolPlacementLaunchButtonText'
    els["#{ALLOWED_ATTEMPTS_CONTAINER}"] = '$allowedAttemptsContainer'
    els["#{ASSIGNMENT_POINTS_POSSIBLE}"] = '$assignmentPointsPossible'
    els["#{ASSIGNMENT_POINTS_CHANGE_WARN}"] = '$pointsChangeWarning'
    els["#{CONDITIONAL_RELEASE_TARGET}"] = '$conditionalReleaseTarget'
    els["#{SIMILARITY_DETECTION_TOOLS}"] = '$similarityDetectionTools'
    els["#{SECURE_PARAMS}"] = '$secureParams'
    els["#{ANONYMOUS_GRADING_BOX}"] = '$anonymousGradingBox'
    els["#{ASSIGNMENT_EXTERNAL_TOOLS}"] = '$assignmentExternalTools'
    els
  )

  events: _.extend({}, @::events, do ->
    events = {}
    events["click .cancel_button"] = 'handleCancel'
    events["click .save_and_publish"] = 'saveAndPublish'
    events["click .save_button"] = 'handleSave'
    events["change #{SUBMISSION_TYPE}"] = 'handleSubmissionTypeChange'
    events["change #{ONLINE_SUBMISSION_TYPES}"] = 'handleOnlineSubmissionTypeChange'
    events["change #{RESTRICT_FILE_UPLOADS}"] = 'handleRestrictFileUploadsChange'
    events["click #{ADVANCED_TURNITIN_SETTINGS}"] = 'showTurnitinDialog'
    events["change #{TURNITIN_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
    events["change #{VERICITE_ENABLED}"] = 'toggleAdvancedTurnitinSettings'
    events["change #{ALLOW_FILE_UPLOADS}"] = 'toggleRestrictFileUploads'
    events["change #{ALLOW_ANNOTATED_DOCUMENT}"] = 'toggleAnnotatedDocument'
    events["click #{EXTERNAL_TOOLS_URL}_find"] = 'showExternalToolsDialog'
    events["change #assignment_points_possible"] = 'handlePointsChange'
    events["change #{PEER_REVIEWS_BOX}"] = 'togglePeerReviewsAndGroupCategoryEnabled'
    events["change #{GROUP_CATEGORY_BOX}"] = 'handleGroupCategoryChange'
    events["change #{ANONYMOUS_GRADING_BOX}"] = 'handleAnonymousGradingChange'
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
    @on 'success', () =>
      annotatedDocument = @getAnnotatedDocument()
      if !!annotatedDocument and @assignment.get("submission_types")?.includes('student_annotation')
        usageRights = @getAnnotatedDocumentUsageRights()
        annotatedDocumentModel = new File(annotatedDocument, { parse: true })
        setUsageRights(
          [annotatedDocumentModel],
          usageRights,
          (->),
          annotatedDocument.contextId,
          annotatedDocument.contextType
        ).always(() =>
          @unwatchUnload()
          @redirectAfterSave()
        )
      else
        @unwatchUnload()
        @redirectAfterSave()
    @gradingTypeSelector.on 'change:gradingType', @handleGradingTypeChange
    if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      @gradingTypeSelector.on 'change:gradingType', @onChange

    @lockedItems = options.lockedItems || {};
    @cannotEditGrades = !options.canEditGrades

  handleCancel: (ev) =>
    ev.preventDefault()
    @cancel()
    @redirectAfterCancel()

  settingsToCache:() =>
    ["assignment_group_id","grading_type","submission_type","submission_types",
      "points_possible","allowed_extensions","peer_reviews","peer_review_count",
      "automatic_peer_reviews","group_category_id","grade_group_students_individually",
      "turnitin_enabled", "vericite_enabled", "allowed_attempts"]

  handlePointsChange:(ev) =>
    ev.preventDefault()
    if (numberHelper.validate(@$assignmentPointsPossible.val()))
      newPoints = round(numberHelper.parse(@$assignmentPointsPossible.val()), 2)
      @$assignmentPointsPossible.val(I18n.n(newPoints))

    if @assignment.hasSubmittedSubmissions()
      @$pointsChangeWarning.toggleAccessibly(@$assignmentPointsPossible.val() != "#{@assignment.pointsPossible()}")

  checkboxAccessibleAdvisory: (box) ->
    label = box.parent()
    srOnly = if box == @$peerReviewsBox || box == @$groupCategoryBox || box == @$anonymousGradingBox
      ""
    else
      "screenreader-only"

    advisory = label.find('div.accessible_label')
    advisory = $("<div class='#{srOnly} accessible_label' style='font-size: 0.9em'></div>").appendTo(label) unless advisory.length
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
    isAnonymous = @$anonymousGradingBox.prop('checked')

    if isAnonymous
      @$groupCategoryBox.prop('checked', false)
    else if isGrouped
      annotatedDocumentCheckbox = document.getElementById('assignment_annotated_document')
      @disableCheckbox(@$allowAnnotatedDocument, I18n.t('Student annotation assignments are not currently supported for group assignments'))
      @disableCheckbox(@$anonymousGradingBox, I18n.t('Anonymous grading cannot be enabled for group assignments'))
    else
      @enableCheckbox(@$anonymousGradingBox)
      @enableCheckbox(@$allowAnnotatedDocument)

    @$intraGroupPeerReviews.toggleAccessibly(isGrouped)
    @togglePeerReviewsAndGroupCategoryEnabled()

  handleAnonymousGradingChange: ->
    isGrouped = @$groupCategoryBox.prop('checked')
    isAnonymous = !isGrouped && @$anonymousGradingBox.prop('checked')
    isAnnotated = @$allowAnnotatedDocument.prop('checked')
    @assignment.anonymousGrading(isAnonymous)

    if isGrouped
      @$anonymousGradingBox.prop('checked', false)
    else if @assignment.anonymousGrading() || @assignment.gradersAnonymousToGraders()
      @disableCheckbox(@$groupCategoryBox, I18n.t('Group assignments cannot be enabled for anonymously graded assignments'))
    else if !@assignment.moderatedGrading()
      if isAnnotated
        @disableCheckbox(@$groupCategoryBox, I18n.t('Group assignments do not currently support student annotation assignments'))
      else
        @enableCheckbox(@$groupCategoryBox) if @model.canGroup()

  togglePeerReviewsAndGroupCategoryEnabled: =>
    if @assignment.moderatedGrading()
      @disableCheckbox(@$peerReviewsBox, I18n.t("Peer reviews cannot be enabled for moderated assignments"))
      @disableCheckbox(@$groupCategoryBox, I18n.t("Group assignments cannot be enabled for moderated assignments"))
    else
      @enableCheckbox(@$peerReviewsBox)
      @enableCheckbox(@$groupCategoryBox) if @model.canGroup()
    @renderModeratedGradingFormFieldGroup()

  setDefaultsIfNew: =>
    if @assignment.isNew()
      if userSettings.contextGet('new_assignment_settings')
        _.each(@settingsToCache(), (setting) =>
          setting_from_cache = userSettings.contextGet('new_assignment_settings')[setting]
          if setting_from_cache == "1" || setting_from_cache == "0"
            setting_from_cache = parseInt setting_from_cache
          if setting_from_cache && (!@assignment.get(setting)? || @assignment.get(setting)?.length == 0)
            @assignment.set(setting, setting_from_cache)
          # special case for allowed_attempts because it defaults to -1
          if setting_from_cache && setting == "allowed_attempts"
            setting_from_cache = parseInt(setting_from_cache, 10)
            setting_from_cache = -1 if Number.isNaN(setting_from_cache)
            @assignment.set(setting, setting_from_cache)
        )
      if @assignment.submissionTypes().length == 0
        @assignment.submissionTypes(['online'])

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

  handleAssignmentSelectionSubmit: (data) =>
    @$externalToolsCustomParams.val(data['item[custom_params]'])
    @$externalToolsContentType.val(data['item[type]'])
    @$externalToolsContentId.val(data['item[id]'])
    @$externalToolsUrl.val(data['item[url]'])
    @$externalToolsNewTab.prop('checked', data['item[new_tab]'] == '1')
    @$externalToolsIframeWidth.val(data['item[iframe][width]'])
    @$externalToolsIframeHeight.val(data['item[iframe][height]'])

    # a content item with an assignment_id means that an assignment was already
    # created on the backend. redirect to that assignment so that user can make
    # any desired changes, without having to populate this model with extra
    # data not found in this content item
    if (data['item[assignment_id]'])
      message = I18n.t("Loading assignment details from external app")
      $.flashMessage(message)
      $.screenReaderFlashMessageExclusive(message)
      [context_type, context_id] = ENV.context_asset_string.split("_")
      window.location.href = "/#{context_type}s/#{context_id}/assignments/#{data['item[assignment_id]']}/edit"

  # assignment_selection placement
  showExternalToolsDialog: =>
    # TODO: don't use this dumb thing
    INST.selectContentDialog
      dialog_title: I18n.t('select_external_tool_dialog_title', 'Configure External Tool')
      select_button_text: I18n.t('buttons.select_url', 'Select'),
      no_name_input: true,
      submit: (data) =>
       @handleAssignmentSelectionSubmit(data)

  toggleRestrictFileUploads: =>
    @$restrictFileUploadsOptions.toggleAccessibly @$allowFileUploads.prop('checked')

  toggleAnnotatedDocument: =>
    isAnonymous = @$anonymousGradingBox.prop('checked')
    @$annotatedDocumentOptions.toggleAccessibly @$allowAnnotatedDocument.prop('checked')

    if @$allowAnnotatedDocument.prop('checked')
      @disableCheckbox(@$groupCategoryBox, I18n.t('Group assignments do not currently support student annotation assignments'))
      @renderAnnotatedDocumentSelector()
      @renderAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()
      @$allowAnnotatedDocumentInfo.show()
    else
      if isAnonymous
        @disableCheckbox(@$groupCategoryBox, I18n.t('Group assignments cannot be enabled for anonymously graded assignments'))
      else if @model.canGroup()
        @enableCheckbox(@$groupCategoryBox)
      @unmountAnnotatedDocumentSelector()
      @unmountAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()
      @$allowAnnotatedDocumentInfo.hide()

  getAnnotatedDocumentContainer: =>
    return document.querySelector('#annotated_document_chooser_container')

  setAnnotatedDocument: (file) =>
    $annotatableAttachmentInput = document.getElementById('annotatable_attachment_id')
    @annotatedDocument = file

    if @annotatedDocument == null
      $annotatableAttachmentInput.value = ''
    else
      $annotatableAttachmentInput.value = @annotatedDocument.id

  getAnnotatedDocument: () =>
    return @annotatedDocument

  renderAnnotatedDocumentSelector: () =>
    props = {
      attachment: @getAnnotatedDocument(),
      defaultUploadFolderId: ENV.ROOT_FOLDER_ID,
      onRemove: (fileInfo) =>
        $.screenReaderFlashMessageExclusive(
          I18n.t('removed %{filename}', {filename: fileInfo.name})
        )
        @setAnnotatedDocument(null)
        @renderAnnotatedDocumentSelector()
        @renderAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()
      onSelect: (fileInfo) =>
        $.screenReaderFlashMessageExclusive(
          I18n.t('selected %{filename}', {filename: fileInfo.name})
        )
        match = fileInfo.src.match(/\/(\w+)\/(\d+)\/files\/.*/)
        @setAnnotatedDocument({
          id: fileInfo.id,
          name: fileInfo.name,
          contextType: match[1],
          contextId: match[2]
        })
        @renderAnnotatedDocumentSelector()
        @renderAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()
    }

    element = React.createElement(AnnotatedDocumentSelector, props)
    ReactDOM.render(element, @getAnnotatedDocumentContainer())

  unmountAnnotatedDocumentSelector: () =>
    ReactDOM.unmountComponentAtNode(@getAnnotatedDocumentContainer())
    @setAnnotatedDocument(null)

  shouldRenderUsageRights: =>
    ENV.USAGE_RIGHTS_REQUIRED

  setAnnotatedDocumentUsageRights:(usageRights) =>
    @annotatedDocumentUsageRights = usageRights
    if @annotatedDocumentUsageRights == null
      return
    $(USAGE_RIGHTS_SELECTOR).val(@annotatedDocumentUsageRights.use_justification).trigger('change')
    # WORKAROUND: Used for trigger React's select onChange SyntheticEvent
    $(USAGE_RIGHTS_SELECTOR).get(0).dispatchEvent(new Event('change', { bubbles: true }))
    if ($(CREATIVE_COMMONS_SELECTION).length)
      $(CREATIVE_COMMONS_SELECTION).val(@annotatedDocumentUsageRights.license)
    $(COPYRIGHT_HOLDER).val(@annotatedDocumentUsageRights.legal_copyright)

  getAnnotatedDocumentUsageRights: () =>
    useJustification = $(USAGE_RIGHTS_SELECTOR).val()
    annotatedDocumentUsageRights = {}
    annotatedDocumentUsageRights.use_justification = useJustification
    @$creativeCommonsSelection = $("#{CREATIVE_COMMONS_SELECTION}")
    if useJustification == 'creative_commons' && @$creativeCommonsSelection.length
      annotatedDocumentUsageRights.license = @$creativeCommonsSelection.val()
    annotatedDocumentUsageRights.legal_copyright = $(COPYRIGHT_HOLDER).val()
    annotatedDocumentUsageRights

  fetchAttachmentFile:(fileId, callback, errorCallback) =>
    baseUrl = "/api/v1/files/#{fileId}"
    params = { include: ['usage_rights'] }
    url = "#{baseUrl}?#{param(params)}"
    $.getJSON(url)
      .pipe((response) -> callback(response))
      .fail(() -> errorCallback())

  renderAnnotatedDocumentUsageRightsSelectBox:() =>
    annotatedDocument = @getAnnotatedDocument()
    if annotatedDocument
      { contextType, contextId } = annotatedDocument
      ReactDOM.render(
        React.createElement(UsageRightsSelectBox, { contextType, contextId }),
        document.querySelector(USAGE_RIGHTS_CONTAINER)
      )
      $("#{USAGE_RIGHTS_CONTAINER} .UsageRightsSelectBox__container").addClass("edit-view")
      self = @
      @fetchAttachmentFile(annotatedDocument.id,
        (document) -> self.setAnnotatedDocumentUsageRights(document.usage_rights),
        () ->
          message = I18n.t("Failed to load student annotation file data.")
          $.flashError(message)
          $.screenReaderFlashMessage(message)
      )
    else
      @unmountAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()

  unmountAnnotatedDocumentUsageRightsSelectBox: () =>
    ReactDOM.unmountComponentAtNode(document.querySelector(USAGE_RIGHTS_CONTAINER))
    @setAnnotatedDocumentUsageRights(null)

  toggleAdvancedTurnitinSettings: (ev) =>
    ev.preventDefault()
    @$advancedTurnitinSettings.toggleAccessibly (@$turnitinEnabled.prop('checked') || @$vericiteEnabled.prop('checked'))

  defaultExternalToolEnabled: =>
    !!@defaultExternalToolUrl()

  defaultExternalToolUrl: =>
    ENV.DEFAULT_ASSIGNMENT_TOOL_URL

  defaultExternalToolName: =>
    ENV.DEFAULT_ASSIGNMENT_TOOL_NAME

  renderDefaultExternalTool: =>
    props = {
      toolDialog: $("#resource_selection_dialog"),
      courseId: ENV.COURSE_ID,
      toolUrl: @defaultExternalToolUrl(),
      toolName: @defaultExternalToolName(),
      toolButtonText: ENV.DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT,
      toolInfoMessage: ENV.DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE,
      previouslySelected: @assignment.defaultToolSelected()
    }

    ReactDOM.render(
      React.createElement(DefaultToolForm, props),
      document.querySelector('[data-component="DefaultToolForm"]')
    )

  handleRestrictFileUploadsChange: =>
    @$allowedExtensions.toggleAccessibly @$restrictFileUploads.prop('checked')

  handleGradingTypeChange: (gradingType) =>
    @$gradedAssignmentFields.toggleAccessibly gradingType != 'not_graded'
    @handleSubmissionTypeChange(null)

  handleSubmissionTypeChange: (ev) =>
    subVal = @$submissionType.val()
    @$onlineSubmissionTypes.toggleAccessibly subVal == 'online'
    @$externalToolSettings.toggleAccessibly subVal == 'external_tool'

    isPlacementTool = subVal.includes("external_tool_placement")
    @$externalToolPlacementLaunchContainer.toggleAccessibly(isPlacementTool)
    @handlePlacementExternalToolSelect(subVal) if isPlacementTool

    @$groupCategorySelector.toggleAccessibly subVal != 'external_tool' && !isPlacementTool
    @$peerReviewsFields.toggleAccessibly subVal != 'external_tool' && !isPlacementTool
    @$similarityDetectionTools.toggleAccessibly subVal == 'online' && ENV.PLAGIARISM_DETECTION_PLATFORM
    @$defaultExternalToolContainer.toggleAccessibly subVal == 'default_external_tool'
    @$allowedAttemptsContainer.toggleAccessibly subVal == 'online' || subVal == 'external_tool' || isPlacementTool
    if subVal == 'online'
      @handleOnlineSubmissionTypeChange()
    @$externalToolNewTabContainer.toggleAccessibly subVal.includes('external_tool')

  handlePlacementExternalToolSelect: (selection) =>
    toolId = selection.replace("external_tool_placement_", "")
    # set the hidden inputs so we'll save the tool on the content tag the way we would normally
    @$externalToolsContentId.val(toolId)
    @$externalToolsContentType.val('context_external_tool')

    @selectedTool = _.find(@model.submissionTypeSelectionTools(), (tool) -> toolId == tool.id)

    # this will prevent overriding URL when data is already saved
    if (!@$externalToolExternalData.val())
      @$externalToolsUrl.val(@selectedTool.external_url)

    @$externalToolPlacementLaunchButtonText.text(@selectedTool.title)
    @$externalToolPlacementLaunchButton.click(() => @handleSubmissionTypeSelectionLaunch())

  handleSubmissionTypeSelectionLaunch: =>
    @renderSubmissionTypeSelectionDialog(true)

  handleSubmissionTypeSelectionDialogClose: =>
    @renderSubmissionTypeSelectionDialog(false)

  renderSubmissionTypeSelectionDialog: (open) =>
    contextInfo = ENV.context_asset_string.split('_')
    contextType = contextInfo[0]
    contextId = parseInt(contextInfo[1], 10)

    props = {
      tool: {
        definition_id: @selectedTool.id,
        placements: {
          submission_type_selection: {
            launch_width: @selectedTool.selection_width,
            launch_height: @selectedTool.selection_height
          }
        }
      }
      title: @selectedTool.title
      isOpen: open
      onRequestClose: @handleSubmissionTypeSelectionDialogClose
      contextType: contextType
      contextId: contextId
      launchType: 'submission_type_selection'
      onExternalContentReady: @handleExternalContentReady
    }

    mountPoint = document.querySelector('#assignment_submission_type_selection_tool_dialog')
    dialog = React.createElement(ExternalToolModalLauncher, props)
    ReactDOM.render(dialog, mountPoint)

  handleExternalContentReady: (data) =>
    if !data.contentItems || data.contentItems.length == 0
      return
    item = data.contentItems[0]
    @$externalToolsUrl.val(item.url)
    if (item.title)
      @$name.val(item.title)

    mc_ext = item[LTI_EXT_MASTERY_CONNECT]
    if mc_ext
      mc_ext['key'] = LTI_EXT_MASTERY_CONNECT
      @$assignmentPointsPossible.val(mc_ext.points)
      @$externalToolExternalData.val(JSON.stringify(mc_ext))
      $("#mc_external_data_assessment").text(item.title)
      $("#mc_external_data_points").text(mc_ext.points + " " + I18n.t('points'))
      $("#mc_external_data_objectives").text(mc_ext.objectives)
      $("#mc_external_data_tracker").text(mc_ext.trackerName)
      $("#mc_external_data_tracker_alignment").text(mc_ext.trackerAlignment)

      student_count_text = I18n.t({
        zero: '0 Students',
        one: '1 Student',
        other: '%{count} Students'
      }, {count: mc_ext.studentCount})
      $("#mc_external_data_students").text(student_count_text)

      showFlashAlert({
        message: I18n.t('Assignment details updated'),
        type: 'info'
      })

  handleOnlineSubmissionTypeChange: (env) =>
    showConfigTools = @$onlineSubmissionTypes.find(ALLOW_FILE_UPLOADS).attr('checked') ||
      @$onlineSubmissionTypes.find(ALLOW_TEXT_ENTRY).attr('checked')
    @$similarityDetectionTools.toggleAccessibly showConfigTools && ENV.PLAGIARISM_DETECTION_PLATFORM

  afterRender: =>
    # have to do these here because they're rendered by other things
    @$peerReviewsBox = $("#{PEER_REVIEWS_BOX}")
    @$intraGroupPeerReviews = $("#{INTRA_GROUP_PEER_REVIEWS}")
    @$groupCategoryBox = $("#{GROUP_CATEGORY_BOX}")
    @$anonymousGradingBox = $("#{ANONYMOUS_GRADING_BOX}")
    @renderModeratedGradingFormFieldGroup()
    @renderAllowedAttempts()
    @$graderCommentsVisibleToGradersBox = $('#assignment_grader_comment_visibility')
    @$gradersAnonymousToGradersLabel = $('label[for="assignment_graders_anonymous_to_graders"]')

    @similarityDetectionTools = SimilarityDetectionTools.attach(
          @$similarityDetectionTools.get(0),
          parseInt(ENV.COURSE_ID),
          @$secureParams.val(),
          parseInt(ENV.SELECTED_CONFIG_TOOL_ID),
          ENV.SELECTED_CONFIG_TOOL_TYPE,
          ENV.REPORT_VISIBILITY_SETTING)

    @AssignmentExternalTools = AssignmentExternalTools.attach(
          @$assignmentExternalTools.get(0),
          "assignment_edit",
          parseInt(ENV.COURSE_ID),
          parseInt(@assignment.id))

    @_attachEditorToDescription()
    @togglePeerReviewsAndGroupCategoryEnabled()
    @handleOnlineSubmissionTypeChange()
    @handleSubmissionTypeChange()
    @handleGroupCategoryChange()
    @handleAnonymousGradingChange()

    if ENV.ANNOTATED_DOCUMENT
      @setAnnotatedDocument({
        id: ENV.ANNOTATED_DOCUMENT.id,
        name: ENV.ANNOTATED_DOCUMENT.display_name,
        contextType: pluralize(ENV.ANNOTATED_DOCUMENT.context_type).toLowerCase(),
        contextId: ENV.ANNOTATED_DOCUMENT.context_id,
      })

    @renderAnnotatedDocumentSelector() if @$allowAnnotatedDocument.prop('checked')

    if @$allowAnnotatedDocument.prop('checked')
      @$allowAnnotatedDocumentInfo.show()
    else
      @$allowAnnotatedDocumentInfo.hide()

    @renderAnnotatedDocumentUsageRightsSelectBox() if @shouldRenderUsageRights()

    if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      @conditionalReleaseEditor = ConditionalRelease.attach(
        @$conditionalReleaseTarget.get(0),
        I18n.t('assignment'),
        ENV.CONDITIONAL_RELEASE_ENV)

    @disableFields() if @assignment.inClosedGradingPeriod()

    @renderDefaultExternalTool() if @defaultExternalToolEnabled()

    this

  toJSON: =>
    data = @assignment.toView()

    _.extend data,
      assignment_attempts: ENV?.assignment_attempts_enabled
      kalturaEnabled: ENV?.KALTURA_ENABLED or false
      postToSISEnabled: ENV?.POST_TO_SIS or false
      postToSISName: ENV.SIS_NAME
      isLargeRoster: ENV?.IS_LARGE_ROSTER or false
      conditionalReleaseServiceEnabled: ENV?.CONDITIONAL_RELEASE_SERVICE_ENABLED or false
      lockedItems: @lockedItems
      cannotEditGrades: @cannotEditGrades
      anonymousGradingEnabled: ENV?.ANONYMOUS_GRADING_ENABLED or false
      anonymousInstructorAnnotationsEnabled: ENV?.ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED or false

  _attachEditorToDescription: =>
    return if @lockedItems.content

    RichContentEditor.loadNewEditor(@$description, { focus: true, manageParent: true })

  # -- Data for Submitting --
  _datesDifferIgnoringSeconds: (newDate, originalDate) =>
    newWithoutSeconds = new Date(newDate)
    originalWithoutSeconds = new Date(originalDate)

    # Since a user can't edit the seconds field in the UI and the form also
    # thinks that the seconds is always set to 00, we compare by everything
    # except seconds.
    originalWithoutSeconds.setSeconds(0)
    newWithoutSeconds.setSeconds(0)
    originalWithoutSeconds.getTime() != newWithoutSeconds.getTime()

  _adjustDateValue: (newDate, originalDate) ->
    # If the minutes value of the due date is 59, set the seconds to 59 so
    # the assignment ends up due one second before the following hour.
    # Otherwise, set it to 0 seconds.
    #
    # If the user has not changed the due date, don't touch the seconds value
    # (so that we don't clobber a due date set by the API).
    return null unless newDate

    adjustedDate = new Date(newDate)
    originalDate = new Date(originalDate)

    if @_datesDifferIgnoringSeconds(adjustedDate, originalDate)
      adjustedDate.setSeconds(if adjustedDate.getMinutes() == 59 then 59 else 0)
    else
      adjustedDate.setSeconds(originalDate.getSeconds())

    adjustedDate.toISOString()

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
    if defaultDates?
      data.due_at = @_adjustDateValue(defaultDates.get('due_at'), @model.dueAt())
      data.lock_at = @_adjustDateValue(defaultDates.get('lock_at'), @model.lockAt())
      data.unlock_at = @_adjustDateValue(defaultDates.get('unlock_at'), @model.unlockAt())
    else
      data.due_at = null
      data.lock_at = null
      data.unlock_at = null

    data.only_visible_to_overrides = !@dueDateOverrideView.overridesContainDefault()
    data.assignment_overrides = @dueDateOverrideView.getOverrides()
    data.published = true if @shouldPublish
    data.points_possible = round(numberHelper.parse(data.points_possible), 2)
    data.peer_review_count = numberHelper.parse(data.peer_review_count) if data.peer_review_count
    $grader_count = $('#grader_count')
    # The custom_params are stored as a JSONified string in a hidden input, but the API uses an
    # actual JSON object, so we have to convert.
    if data.external_tool_tag_attributes.custom_params.trim()
      data.external_tool_tag_attributes.custom_params = JSON.parse(data.external_tool_tag_attributes.custom_params)

    if $grader_count.length > 0
      data.grader_count = numberHelper.parse($grader_count[0].value)
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

    # Get the submission type if an alias type is used (e.g. default_external_tool)
    $(SUBMISSION_TYPE).val(@toolSubmissionType($(SUBMISSION_TYPE).val()))

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

  toolSubmissionType: (submissionType) ->
    if (submissionType == 'default_external_tool' || submissionType.includes("external_tool_placement"))
      'external_tool'
    else
      submissionType

  saveAndPublish: (event) ->
    @shouldPublish = true
    @disableWhileLoadingOpts = {buttons: ['.save_and_publish']}
    @preventBuildNavigation = true
    @submit(event)

  handleSave: (event) =>
    @preventBuildNavigation = true
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
    GroupCategorySelector::fieldSelectors,
    {grader_count: "#grader_count"},
    {usage_rights_use_justification: USAGE_RIGHTS_SELECTOR},
    {usage_rights_legal_copyright: COPYRIGHT_HOLDER}
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
    Object.assign(errors, @validateFinalGrader(data))
    Object.assign(errors, @validateGraderCount(data))
    unless ENV?.IS_LARGE_ROSTER
      errors = @groupCategorySelector.validateBeforeSave(data, errors)
    errors = @_validatePointsPossible(data, errors)
    errors = @_validatePointsRequired(data, errors)
    errors = @_validateExternalTool(data, errors)
    errors = @_validateAllowedAttempts(data, errors)
    data2 =
      assignment_overrides: @dueDateOverrideView.getAllDates(),
      postToSIS: data.post_to_sis == '1'
    errors = @dueDateOverrideView.validateBeforeSave(data2,errors)
    if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      crErrors = @conditionalReleaseEditor.validateBeforeSave()
      errors['conditional_release'] = crErrors if crErrors
    errors

  validateFinalGrader: (data) =>
    errors = {}
    if data.moderated_grading == 'on' and !data.final_grader_id
      errors.final_grader_id = [{ message: I18n.t('Grader is required') }]

    errors

  validateGraderCount: (data) =>
    errors = {}
    return errors unless data.moderated_grading == 'on'

    if !data.grader_count
      errors.grader_count = [{ message: I18n.t('Grader count is required') }]
    else if data.grader_count == '0'
      errors.grader_count = [{ message: I18n.t('Grader count cannot be 0') }]
    else if parseInt(data.grader_count, 10) > ENV.MODERATED_GRADING_GRADER_LIMIT
      errors.grader_count = [{ message: I18n.t('Only a maximum of %{max} graders can be assigned', {max: ENV.MODERATED_GRADING_GRADER_LIMIT}) }]

    errors

  _validateTitle: (data, errors) =>
    return errors if _.includes(@model.frozenAttributes(), "title")

    post_to_sis = data.post_to_sis == '1'
    max_name_length = 256
    if post_to_sis && ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT && data.grading_type != 'not_graded'
      max_name_length = ENV.MAX_NAME_LENGTH

    validationHelper = new SisValidationHelper({
      postToSIS: post_to_sis
      maxNameLength: max_name_length
      name: data.name
      maxNameLengthRequired: ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT
    })

    if !data.name or $.trim(data.name.toString()).length == 0
      errors["name"] = [
        message: I18n.t 'name_is_required', 'Name is required!'
      ]
    else if validationHelper.nameTooLong()
      errors["name"] = [
        message: I18n.t("Name is too long, must be under %{length} characters", length: max_name_length + 1)
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
    else if !@getAnnotatedDocument() && data.submission_types?.includes('student_annotation')
      errors["online_submission_types[student_annotation]"] = [message: I18n.t('You must attach a file')]
    else if @getAnnotatedDocument() and data.submission_types?.includes('student_annotation') and @shouldRenderUsageRights()
      annotatedDocumentUsageRights = @getAnnotatedDocumentUsageRights()
      if annotatedDocumentUsageRights.use_justification == 'choose'
        errors['usage_rights_use_justification'] = [{message: I18n.t('You must set document usage rights')}]

    errors

  _validateAllowedExtensions: (data, errors) =>
    if (data.allowed_extensions and _.includes(data.submission_types, "online_upload")) and data.allowed_extensions.length == 0
      errors["allowed_extensions"] = [
        message: I18n.t 'at_least_one_file_type', 'Please specify at least one allowed file type'
      ]
    errors

  _validatePointsPossible: (data, errors) =>
    return errors if _.includes(@model.frozenAttributes(), "points_possible")
    return errors if this.lockedItems.points

    if typeof data.points_possible != 'number' or isNaN(data.points_possible)
      errors["points_possible"] = [
        message: I18n.t 'points_possible_number', 'Points possible must be a number'
      ]
    errors

  # Require points possible > 0
  # if grading type === percent || letter_grade || gpa_scale
  _validatePointsRequired: (data, errors) =>
    return errors unless ['percent','letter_grade','gpa_scale'].includes data.grading_type

    if typeof data.points_possible != 'number' or data.points_possible < 0 or isNaN(data.points_possible)
      errors["points_possible"] = [
        message: I18n.t("Points possible must be 0 or more for selected grading type")
      ]
    errors

  _validateExternalTool: (data, errors) =>
    if data.submission_type == 'external_tool' && data.grading_type != 'not_graded' && $.trim(data.external_tool_tag_attributes?.url?.toString()).length == 0
      message = I18n.t 'External Tool URL cannot be left blank'
      errors["external_tool_tag_attributes[url]"] = [
        message: message
      ]
      errors["default-tool-launch-button"] = [
        message: message
      ]
    errors

  _validateAllowedAttempts: (data, errors) =>
    return errors unless ENV?.assignment_attempts_enabled
    return errors if @lockedItems.settings # field will be disabled and not submitted
    value = parseInt(data.allowed_attempts, 10)
    unless value > 0 || value == -1
      errors['allowed_attempts'] = [
        message: I18n.t 'Number of attempts must be a number greater than 0'
      ]
    errors

  redirectAfterSave: ->
    window.location = @locationAfterSave(deparam())

  locationAfterSave: (params) ->
    return params['return_to'] if returnToHelper.isValid(params['return_to']) && !@assignment.showBuildButton()
    useCancelLocation = @assignment.showBuildButton() && @preventBuildNavigation
    return @locationAfterCancel(deparam()) if useCancelLocation
    htmlUrl = @model.get 'html_url'
    if @assignment.showBuildButton() then "#{htmlUrl}?display=full_width" else htmlUrl

  redirectAfterCancel: ->
    location = @locationAfterCancel(deparam())
    window.location = location if location

  locationAfterCancel: (params) ->
    return params['return_to'] if returnToHelper.isValid(params['return_to'])
    if ENV.CAN_CANCEL_TO && ENV.CAN_CANCEL_TO.includes(document.referrer)
      return document.referrer
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

  handleModeratedGradingChanged: (isModerated) =>
    @assignment.moderatedGrading(isModerated)
    @togglePeerReviewsAndGroupCategoryEnabled()

    if isModerated
      @$gradersAnonymousToGradersLabel.show() if @assignment.graderCommentsVisibleToGraders()
    else
      @uncheckAndHideGraderAnonymousToGraders()

  handleGraderCommentsVisibleToGradersChanged: (commentsVisible) =>
    @assignment.graderCommentsVisibleToGraders(commentsVisible)
    if commentsVisible
      @$gradersAnonymousToGradersLabel.show()
    else
      @uncheckAndHideGraderAnonymousToGraders()

  uncheckAndHideGraderAnonymousToGraders: =>
    @assignment.gradersAnonymousToGraders(false)
    $('#assignment_graders_anonymous_to_graders').prop('checked', false)
    @$gradersAnonymousToGradersLabel.hide()

  renderModeratedGradingFormFieldGroup: ->
    return if !ENV.MODERATED_GRADING_ENABLED || @assignment.isQuizLTIAssignment()

    props =
      availableModerators: ENV.AVAILABLE_MODERATORS
      currentGraderCount: @assignment.get('grader_count')
      finalGraderID: @assignment.get('final_grader_id')
      graderCommentsVisibleToGraders: @assignment.graderCommentsVisibleToGraders()
      graderNamesVisibleToFinalGrader: !!@assignment.get('grader_names_visible_to_final_grader')
      gradedSubmissionsExist: ENV.HAS_GRADED_SUBMISSIONS
      isGroupAssignment: !!@$groupCategoryBox.prop('checked')
      isPeerReviewAssignment: !!@$peerReviewsBox.prop('checked')
      locale: ENV.LOCALE
      moderatedGradingEnabled: @assignment.moderatedGrading()
      availableGradersCount: ENV.MODERATED_GRADING_MAX_GRADER_COUNT
      onGraderCommentsVisibleToGradersChange: @handleGraderCommentsVisibleToGradersChanged
      onModeratedGradingChange: @handleModeratedGradingChanged

    formFieldGroup = React.createElement(ModeratedGradingFormFieldGroup, props)
    mountPoint = document.querySelector("[data-component='ModeratedGradingFormFieldGroup']")
    ReactDOM.render(formFieldGroup, mountPoint)

  renderAllowedAttempts: ->
    return if !ENV?.assignment_attempts_enabled
    props = {
      limited: @model.get('allowed_attempts') > 0
      attempts: @model.get('allowed_attempts')
      locked: !!@lockedItems.settings
    }
    mountPoint = document.querySelector('#allowed-attempts-target')
    ReactDOM.render(React.createElement(AllowedAttemptsWithState, props), mountPoint)

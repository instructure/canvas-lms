/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import _, {each, find, keys, includes, forEach, filter} from 'lodash'
import $, {param} from 'jquery'
import pluralize from '@canvas/util/stringPluralize'
import numberHelper from '@canvas/i18n/numberHelper'
import round from '@canvas/round'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import EditViewTemplate from '../../jst/EditView.handlebars'
import userSettings from '@canvas/user-settings'
import TurnitinSettings from '@canvas/assignments/TurnitinSettings'
import VeriCiteSettings from '@canvas/assignments/VeriCiteSettings'
import File from '@canvas/files/backbone/models/File'
import TurnitinSettingsDialog from './TurnitinSettingsDialog'
import MissingDateDialog from '@canvas/due-dates/backbone/views/MissingDateDialogView'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GroupCategorySelector, {
  GROUP_CATEGORY_SELECT,
} from '@canvas/groups/backbone/views/GroupCategorySelector'
import ConditionalRelease from '@canvas/conditional-release-editor'
import deparam from 'deparam'
import SisValidationHelper from '@canvas/sis/SisValidationHelper'
import SimilarityDetectionTools from '../../react/AssignmentConfigurationTools'
import ModeratedGradingFormFieldGroup from '../../react/ModeratedGradingFormFieldGroup'
import AllowedAttemptsWithState from '../../react/allowed_attempts/AllowedAttemptsWithState'
import {AssignmentSubmissionTypeContainer} from '../../react/AssignmentSubmissionTypeContainer'
import DefaultToolForm from '../../react/DefaultToolForm'
import UsageRightsSelectBox from '@canvas/files/react/components/UsageRightsSelectBox'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import {attach as assetProcessorsAttach} from '../../react/AssetProcessors'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import * as returnToHelper from '@canvas/util/validateReturnToURL'
import setUsageRights from '@canvas/files/util/setUsageRights'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.toJSON'
import '@canvas/rails-flash-notifications'
import '@canvas/common/activateTooltips'
import {AnnotatedDocumentSelector} from '../../react/EditAssignment'
import {selectContentDialog} from '@canvas/select-content-dialog'
import {addDeepLinkingListener} from '@canvas/deep-linking/DeepLinking'
import {queryClient} from '@canvas/query'
import {createRoot} from 'react-dom/client'
import YAML from 'yaml'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'

const I18n = createI18nScope('assignment_editview')

const slice = [].slice

const ASSIGNMENT_GROUP_SELECTOR = '#assignment_group_selector'
const DESCRIPTION = '[name="description"]'
const SUBMISSION_TYPE = '[name="submission_type"]'
const ONLINE_SUBMISSION_TYPES = '#assignment_online_submission_types'
const NAME = '[name="name"]'
const ALLOW_FILE_UPLOADS = '#assignment_online_upload'
const ALLOW_ANNOTATED_DOCUMENT = '#assignment_annotated_document'
const ALLOW_ANNOTATED_DOCUMENT_INFO = '#assignment_annotated_document_info'
const ALLOW_TEXT_ENTRY = '#assignment_text_entry'
const RESTRICT_FILE_UPLOADS = '#assignment_restrict_file_extensions'
const RESTRICT_FILE_UPLOADS_OPTIONS = '#restrict_file_extensions_container'
const ANNOTATED_DOCUMENT_OPTIONS = '#annotated_document_chooser_container'
const ALLOWED_EXTENSIONS = '#allowed_extensions_container'
const TURNITIN_ENABLED = '#assignment_turnitin_enabled'
const VERICITE_ENABLED = '#assignment_vericite_enabled'
const ADVANCED_TURNITIN_SETTINGS = '#advanced_turnitin_settings_link'
const GRADING_TYPE_SELECTOR = '#grading_type_selector'
const GRADED_ASSIGNMENT_FIELDS = '#graded_assignment_fields'
const EXTERNAL_TOOL_SETTINGS = '#assignment_external_tool_settings'
const EXTERNAL_TOOL_SETTINGS_NEW_TAB = '#external_tool_new_tab_container'
const DEFAULT_EXTERNAL_TOOL_CONTAINER = '#default_external_tool_container'
const EXTERNAL_TOOL_PLACEMENT_LAUNCH_CONTAINER =
  '#assignment_submission_type_selection_tool_launch_container'

const EXTERNAL_TOOL_DATA = '#assignment_submission_type_external_data'
const ALLOWED_ATTEMPTS_CONTAINER = '#allowed_attempts_fields'
const GROUP_CATEGORY_SELECTOR = '#group_category_selector'
const PEER_REVIEWS_FIELDS = '#assignment_peer_reviews_fields'
const EXTERNAL_TOOLS_URL = '#assignment_external_tool_tag_attributes_url'
const EXTERNAL_TOOLS_TITLE = '#assignment_external_tool_tag_attributes_title'
const EXTERNAL_TOOLS_CONTENT_TYPE = '#assignment_external_tool_tag_attributes_content_type'
const EXTERNAL_TOOLS_CONTENT_ID = '#assignment_external_tool_tag_attributes_content_id'
const EXTERNAL_TOOLS_NEW_TAB = '#assignment_external_tool_tag_attributes_new_tab'
const EXTERNAL_TOOLS_IFRAME_WIDTH = '#assignment_external_tool_tag_attributes_iframe_width'
const EXTERNAL_TOOLS_IFRAME_HEIGHT = '#assignment_external_tool_tag_attributes_iframe_height'
const EXTERNAL_TOOLS_CUSTOM_PARAMS = '#assignment_external_tool_tag_attributes_custom_params'
const EXTERNAL_TOOLS_LINE_ITEM = '#assignment_external_tool_tag_attributes_line_item'
const ASSIGNMENT_POINTS_POSSIBLE = '#assignment_points_possible'
const ASSIGNMENT_POINTS_CHANGE_WARN = '#point_change_warning'
const SECURE_PARAMS = '#secure_params'
const PEER_REVIEWS_BOX = '#assignment_peer_reviews'
const POST_TO_SIS_BOX = '#assignment_post_to_sis'
const INTRA_GROUP_PEER_REVIEWS = '#intra_group_peer_reviews_toggle'
const GROUP_CATEGORY_BOX = '#has_group_category'
const CONDITIONAL_RELEASE_TARGET = '#conditional_release_target'
const SIMILARITY_DETECTION_TOOLS = '#similarity_detection_tools'
const ANONYMOUS_GRADING_BOX = '#assignment_anonymous_grading'
const HIDE_ZERO_POINT_QUIZZES_BOX = '#assignment_hide_in_gradebook'
const HIDE_ZERO_POINT_QUIZZES_OPTION = '#assignment_hide_in_gradebook_option'
const OMIT_FROM_FINAL_GRADE_BOX = '#assignment_omit_from_final_grade'
const SUPPRESS_FROM_GRADEBOOK = '#assignment_suppress_from_gradebook'
const ASSIGNMENT_EXTERNAL_TOOLS = '#assignment_external_tools'
const USAGE_RIGHTS_CONTAINER = '#annotated_document_usage_rights_container'
const USAGE_RIGHTS_SELECTOR = '#usageRightSelector'
const COPYRIGHT_HOLDER = '#copyrightHolder'
const CREATIVE_COMMONS_SELECTION = '#creativeCommonsSelection'
const LTI_EXT_MASTERY_CONNECT = 'https://canvas.instructure.com/lti/mastery_connect_assessment'

const DEFAULT_SUBMISSION_TYPE_SELECTION_CONTENT_TYPE = 'context_external_tool'

const ASSIGNMENT_NAME_INPUT_NAME = 'name'
const POINTS_POSSIBLE_INPUT_NAME = 'points_possible'
const EXTERNAL_TOOL_URL_INPUT_NAME = 'external_tool_tag_attributes[url]'
const ASSET_PROCESSORS_CONTAINER = '#asset_processors_container'
const ALLOWED_EXTENSIONS_INPUT_NAME = 'allowed_extensions'
const ONLINE_SUBMISSION_CHECKBOXES_GROUP = 'online_submission_types[online_text_entry]'
const DEFAULT_TOOL_LAUNCH_BUTTON = 'default-tool-launch-button'
const SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON = 'assignment_submission_type_selection_launch_button'
const USAGE_RIGHTS_SELECT = 'usage_rights_use_justification'

/*
xsslint safeString.identifier srOnly
 */

RichContentEditor.preloadRemoteModule()

extend(EditView, ValidatedFormView)

function EditView() {
  this.uncheckAndHideGraderAnonymousToGraders =
    this.uncheckAndHideGraderAnonymousToGraders.bind(this)
  this.handleGraderCommentsVisibleToGradersChanged =
    this.handleGraderCommentsVisibleToGradersChanged.bind(this)
  this.handleModeratedGradingChanged = this.handleModeratedGradingChanged.bind(this)
  this._validateAllowedAttempts = this._validateAllowedAttempts.bind(this)
  this._validateExternalTool = this._validateExternalTool.bind(this)
  this._validatePointsPossible = this._validatePointsPossible.bind(this)
  this._validateAllowedExtensions = this._validateAllowedExtensions.bind(this)
  this._validateSubmissionTypes = this._validateSubmissionTypes.bind(this)
  this._validateTitle = this._validateTitle.bind(this)
  this.validateGraderCount = this.validateGraderCount.bind(this)
  this.validateFinalGrader = this.validateFinalGrader.bind(this)
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  this._unsetGroupsIfExternalTool = this._unsetGroupsIfExternalTool.bind(this)
  this._filterAllowedExtensions = this._filterAllowedExtensions.bind(this)
  this._inferSubmissionTypes = this._inferSubmissionTypes.bind(this)
  this.onSaveFail = this.onSaveFail.bind(this)
  this.handleSave = this.handleSave.bind(this)
  this.submit = this.submit.bind(this)
  this.saveFormData = this.saveFormData.bind(this)
  this.getFormData = this.getFormData.bind(this)
  this._datesDifferIgnoringSeconds = this._datesDifferIgnoringSeconds.bind(this)
  this._attachEditorToDescription = this._attachEditorToDescription.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.afterRender = this.afterRender.bind(this)
  this.handleOnlineSubmissionTypeChange = this.handleOnlineSubmissionTypeChange.bind(this)
  this.handleExternalContentReady = this.handleExternalContentReady.bind(this)
  this.renderSubmissionTypeSelectionDialog = this.renderSubmissionTypeSelectionDialog.bind(this)
  this.handleSubmissionTypeSelectionDialogClose =
    this.handleSubmissionTypeSelectionDialogClose.bind(this)
  this.handleSubmissionTypeSelectionLaunch = this.handleSubmissionTypeSelectionLaunch.bind(this)
  this.handlePlacementExternalToolSelect = this.handlePlacementExternalToolSelect.bind(this)
  this.handleRemoveResource = this.handleRemoveResource.bind(this)
  this.handleSubmissionTypeChange = this.handleSubmissionTypeChange.bind(this)
  this.handleGradingTypeChange = this.handleGradingTypeChange.bind(this)
  this.handleRestrictFileUploadsChange = this.handleRestrictFileUploadsChange.bind(this)
  this.renderDefaultExternalTool = this.renderDefaultExternalTool.bind(this)
  this.renderAssignmentSubmissionTypeContainer =
    this.renderAssignmentSubmissionTypeContainer.bind(this)
  this.defaultExternalToolName = this.defaultExternalToolName.bind(this)
  this.defaultExternalToolUrl = this.defaultExternalToolUrl.bind(this)
  this.defaultExternalToolEnabled = this.defaultExternalToolEnabled.bind(this)
  this.toggleAdvancedTurnitinSettings = this.toggleAdvancedTurnitinSettings.bind(this)
  this.unmountAnnotatedDocumentUsageRightsSelectBox =
    this.unmountAnnotatedDocumentUsageRightsSelectBox.bind(this)
  this.renderAnnotatedDocumentUsageRightsSelectBox =
    this.renderAnnotatedDocumentUsageRightsSelectBox.bind(this)
  this.fetchAttachmentFile = this.fetchAttachmentFile.bind(this)
  this.getAnnotatedDocumentUsageRights = this.getAnnotatedDocumentUsageRights.bind(this)
  this.setAnnotatedDocumentUsageRights = this.setAnnotatedDocumentUsageRights.bind(this)
  this.shouldRenderUsageRights = this.shouldRenderUsageRights.bind(this)
  this.unmountAnnotatedDocumentSelector = this.unmountAnnotatedDocumentSelector.bind(this)
  this.renderAnnotatedDocumentSelector = this.renderAnnotatedDocumentSelector.bind(this)
  this.getAnnotatedDocument = this.getAnnotatedDocument.bind(this)
  this.setAnnotatedDocument = this.setAnnotatedDocument.bind(this)
  this.getAnnotatedDocumentContainer = this.getAnnotatedDocumentContainer.bind(this)
  this.toggleAnnotatedDocument = this.toggleAnnotatedDocument.bind(this)
  this.toggleRestrictFileUploads = this.toggleRestrictFileUploads.bind(this)
  this.showExternalToolsDialog = this.showExternalToolsDialog.bind(this)
  this.handleAssignmentSelectionSubmit = this.handleAssignmentSelectionSubmit.bind(this)
  this.handleContentItem = this.handleContentItem.bind(this)
  this.showTurnitinDialog = this.showTurnitinDialog.bind(this)
  this.cacheAssignmentSettings = this.cacheAssignmentSettings.bind(this)
  this.setDefaultsIfNew = this.setDefaultsIfNew.bind(this)
  this.togglePeerReviewsAndGroupCategoryEnabled =
    this.togglePeerReviewsAndGroupCategoryEnabled.bind(this)
  this.handlePointsChange = this.handlePointsChange.bind(this)
  this.settingsToCache = this.settingsToCache.bind(this)
  this.handleCancel = this.handleCancel.bind(this)
  this.handleMessageEvent = this.handleMessageEvent.bind(this)
  window.addEventListener('message', this.handleMessageEvent.bind(this))
  this.hideErrors = this.hideErrors.bind(this)
  this.errorRoots = {}

  return EditView.__super__.constructor.apply(this, arguments)
}
EditView.prototype.template = EditViewTemplate

EditView.prototype.dontRenableAfterSaveSuccess = true

EditView.prototype.els = {
  ...EditView.prototype.els,
  ...(function () {
    const els = {}
    els['' + ASSIGNMENT_GROUP_SELECTOR] = '$assignmentGroupSelector'
    els['' + DESCRIPTION] = '$description'
    els['' + SUBMISSION_TYPE] = '$submissionType'
    els['' + ONLINE_SUBMISSION_TYPES] = '$onlineSubmissionTypes'
    els['' + NAME] = '$name'
    els['' + ALLOW_FILE_UPLOADS] = '$allowFileUploads'
    els['' + ALLOW_ANNOTATED_DOCUMENT] = '$allowAnnotatedDocument'
    els['' + ALLOW_ANNOTATED_DOCUMENT_INFO] = '$allowAnnotatedDocumentInfo'
    els['' + RESTRICT_FILE_UPLOADS] = '$restrictFileUploads'
    els['' + RESTRICT_FILE_UPLOADS_OPTIONS] = '$restrictFileUploadsOptions'
    els['' + ANNOTATED_DOCUMENT_OPTIONS] = '$annotatedDocumentOptions'
    els['' + ALLOWED_EXTENSIONS] = '$allowedExtensions'
    els['' + TURNITIN_ENABLED] = '$turnitinEnabled'
    els['' + VERICITE_ENABLED] = '$vericiteEnabled'
    els['' + ADVANCED_TURNITIN_SETTINGS] = '$advancedTurnitinSettings'
    els['' + GRADING_TYPE_SELECTOR] = '$gradingTypeSelector'
    els['' + GRADED_ASSIGNMENT_FIELDS] = '$gradedAssignmentFields'
    els['' + EXTERNAL_TOOL_SETTINGS] = '$externalToolSettings'
    els['' + GROUP_CATEGORY_SELECTOR] = '$groupCategorySelector'
    els['' + PEER_REVIEWS_FIELDS] = '$peerReviewsFields'
    els['' + EXTERNAL_TOOLS_URL] = '$externalToolsUrl'
    els['' + EXTERNAL_TOOLS_TITLE] = '$externalToolsTitle'
    els['' + EXTERNAL_TOOLS_NEW_TAB] = '$externalToolsNewTab'
    els['' + EXTERNAL_TOOLS_IFRAME_WIDTH] = '$externalToolsIframeWidth'
    els['' + EXTERNAL_TOOLS_IFRAME_HEIGHT] = '$externalToolsIframeHeight'
    els['' + EXTERNAL_TOOLS_LINE_ITEM] = '$externalToolsLineItem'
    els['' + EXTERNAL_TOOLS_CONTENT_TYPE] = '$externalToolsContentType'
    els['' + EXTERNAL_TOOLS_CUSTOM_PARAMS] = '$externalToolsCustomParams'
    els['' + EXTERNAL_TOOLS_CONTENT_ID] = '$externalToolsContentId'
    els['' + EXTERNAL_TOOL_DATA] = '$externalToolExternalData'
    els['' + EXTERNAL_TOOL_SETTINGS_NEW_TAB] = '$externalToolNewTabContainer'
    els['' + DEFAULT_EXTERNAL_TOOL_CONTAINER] = '$defaultExternalToolContainer'
    els['' + EXTERNAL_TOOL_PLACEMENT_LAUNCH_CONTAINER] = '$externalToolPlacementLaunchContainer'
    els['' + ALLOWED_ATTEMPTS_CONTAINER] = '$allowedAttemptsContainer'
    els['' + ASSIGNMENT_POINTS_POSSIBLE] = '$assignmentPointsPossible'
    els['' + ASSIGNMENT_POINTS_CHANGE_WARN] = '$pointsChangeWarning'
    els['' + CONDITIONAL_RELEASE_TARGET] = '$conditionalReleaseTarget'
    els['' + SIMILARITY_DETECTION_TOOLS] = '$similarityDetectionTools'
    els['' + SECURE_PARAMS] = '$secureParams'
    els['' + ANONYMOUS_GRADING_BOX] = '$anonymousGradingBox'
    els['' + POST_TO_SIS_BOX] = '$postToSisBox'
    els['' + ASSIGNMENT_EXTERNAL_TOOLS] = '$assignmentExternalTools'
    els['' + ASSET_PROCESSORS_CONTAINER] = '$assetProcessorsContainer'
    els['' + HIDE_ZERO_POINT_QUIZZES_BOX] = '$hideZeroPointQuizzesBox'
    els['' + HIDE_ZERO_POINT_QUIZZES_OPTION] = '$hideZeroPointQuizzesOption'
    els['' + OMIT_FROM_FINAL_GRADE_BOX] = '$omitFromFinalGradeBox'
    els['' + SUPPRESS_FROM_GRADEBOOK] = '$suppressAssignment'
    return els
  })(),
}

EditView.prototype.events = {
  ...EditView.prototype.events,
  ...(function () {
    const events = {}
    events['click .cancel_button'] = 'handleCancel'
    events['click .save_and_publish'] = 'saveAndPublish'
    events['click .save_button'] = 'handleSave'
    events['change ' + SUBMISSION_TYPE] = 'handleSubmissionTypeChange'
    events['change ' + ONLINE_SUBMISSION_TYPES] = 'handleOnlineSubmissionTypeChange'
    events['change ' + RESTRICT_FILE_UPLOADS] = 'handleRestrictFileUploadsChange'
    events['click ' + ADVANCED_TURNITIN_SETTINGS] = 'showTurnitinDialog'
    events['change ' + TURNITIN_ENABLED] = 'toggleAdvancedTurnitinSettings'
    events['change ' + VERICITE_ENABLED] = 'toggleAdvancedTurnitinSettings'
    events['change ' + ALLOW_FILE_UPLOADS] = 'toggleRestrictFileUploads'
    events['change ' + ALLOW_ANNOTATED_DOCUMENT] = 'toggleAnnotatedDocument'
    events['click ' + EXTERNAL_TOOLS_URL + '_find'] = 'showExternalToolsDialog'
    events['change #assignment_points_possible'] = 'handlePointsChange'
    events['change ' + PEER_REVIEWS_BOX] = 'togglePeerReviewsAndGroupCategoryEnabled'
    events['change ' + POST_TO_SIS_BOX] = 'handlePostToSisBoxChange'
    events['change ' + GROUP_CATEGORY_BOX] = 'handleGroupCategoryChange'
    events['change ' + ANONYMOUS_GRADING_BOX] = 'handleAnonymousGradingChange'
    events['change ' + HIDE_ZERO_POINT_QUIZZES_BOX] = 'handleHideZeroPointQuizChange'
    events['change ' + SUPPRESS_FROM_GRADEBOOK] = 'handlesuppressFromGradebookChange'
    events['input ' + `[name="${EXTERNAL_TOOL_URL_INPUT_NAME}"]`] = 'clearErrorsOnInput'
    events['input ' + `[name="${ASSIGNMENT_NAME_INPUT_NAME}"]`] = 'validateInput'
    events['input ' + `[name="${ALLOWED_EXTENSIONS_INPUT_NAME}"]`] = 'validateInput'
    events['input ' + `[name="${POINTS_POSSIBLE_INPUT_NAME}"]`] = 'validateInput'
    events['change #assignment_online_submission_types input[type="checkbox"]'] =
      'handleOnlineSubmissionCheckboxToggle'
    events['change #' + GROUP_CATEGORY_SELECT] = 'clearGroupSetErrors'
    if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
      events.change = 'onChange'
    }
    return events
  })(),
}

EditView.child('assignmentGroupSelector', '' + ASSIGNMENT_GROUP_SELECTOR)

EditView.child('gradingTypeSelector', '' + GRADING_TYPE_SELECTOR)

EditView.child('groupCategorySelector', '' + GROUP_CATEGORY_SELECTOR)

EditView.child('peerReviewsSelector', '' + PEER_REVIEWS_FIELDS)

EditView.prototype.initialize = function (options) {
  EditView.__super__.initialize.apply(this, arguments)
  this.assignment = this.model
  this.setDefaultsIfNew()
  this.dueDateOverrideView = options.views['js-assignment-overrides']
  this.masteryPathToggleView = options.views['js-assignment-overrides-mastery-path']

  this.on(
    'success',
    (function (_this) {
      return function () {
        const annotatedDocument = _this.getAnnotatedDocument()
        let ref
        if (
          !!annotatedDocument &&
          ((ref = _this.assignment.get('submission_types')) != null
            ? ref.includes('student_annotation')
            : void 0)
        ) {
          const usageRights = _this.getAnnotatedDocumentUsageRights()
          const annotatedDocumentModel = new File(annotatedDocument, {
            parse: true,
          })
          return setUsageRights(
            [annotatedDocumentModel],
            usageRights,
            function () {},
            annotatedDocument.contextId,
            annotatedDocument.contextType,
          ).always(function () {
            _this.unwatchUnload()
            return _this.redirectAfterSave()
          })
        } else {
          _this.unwatchUnload()
          return _this.redirectAfterSave()
        }
      }
    })(this),
  )
  this.gradingTypeSelector.on('change:gradingType', this.handleGradingTypeChange)
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    this.gradingTypeSelector.on('change:gradingType', this.onChange)
  }
  this.lockedItems = options.lockedItems || {}
  return (this.cannotEditGrades = !options.canEditGrades)
}

EditView.prototype.handleCancel = function (ev) {
  ev.preventDefault()
  this.cancel()
  return this.redirectAfterCancel()
}

EditView.prototype.settingsToCache = function () {
  return [
    'assignment_group_id',
    'grading_type',
    'submission_type',
    'submission_types',
    'points_possible',
    'allowed_extensions',
    'peer_reviews',
    'peer_review_count',
    'automatic_peer_reviews',
    'group_category_id',
    'grade_group_students_individually',
    'turnitin_enabled',
    'vericite_enabled',
    'allowed_attempts',
  ]
}

EditView.prototype.handleOnlineSubmissionCheckboxToggle = function (_e) {
  const containerId = `${ONLINE_SUBMISSION_CHECKBOXES_GROUP}_errors`
  this.errorRoots[containerId]?.unmount()
  delete this.errorRoots[containerId]

  document.getElementById('online_entry_options_asterisk')?.classList.remove('error-text')
}

EditView.prototype.clearGroupSetErrors = function (_e) {
  const containerId = `${GROUP_CATEGORY_SELECT}_errors`
  this.hideErrors(containerId)
}

EditView.prototype.handlePointsChange = function (ev) {
  let newPoints
  ev.preventDefault()
  if (numberHelper.validate(this.$assignmentPointsPossible.val())) {
    newPoints = round(numberHelper.parse(this.$assignmentPointsPossible.val()), 2)
    this.$assignmentPointsPossible.val(I18n.n(newPoints))
  }
  if (this.assignment.hasSubmittedSubmissions()) {
    return this.$pointsChangeWarning.toggleAccessibly(
      this.$assignmentPointsPossible.val() !== '' + this.assignment.pointsPossible(),
    )
  }
  if (newPoints === 0) {
    this.$hideZeroPointQuizzesOption.toggleAccessibly(true)
  } else {
    this.$hideZeroPointQuizzesBox.prop('checked', false)
    this.$hideZeroPointQuizzesOption.toggleAccessibly(false)
    this.handleHideZeroPointQuizChange()
  }
}

EditView.prototype.checkboxAccessibleAdvisory = function (box) {
  let advisory
  const label = box.parent()
  const srOnly =
    box === this.$peerReviewsBox ||
    box === this.$groupCategoryBox ||
    box === this.$anonymousGradingBox ||
    box === this.$omitFromFinalGradeBox ||
    box === this.$suppressAssignment
      ? ''
      : 'screenreader-only'
  advisory = label.find('div.accessible_label')
  if (!advisory.length) {
    advisory = $(
      "<div class='" + srOnly + " accessible_label' style='font-size: 0.9em'></div>",
    ).appendTo(label)
  }
  return advisory
}

EditView.prototype.setImplicitCheckboxValue = function (box, value) {
  return $("input[type='hidden'][name='" + box.attr('name') + "']", box.parent()).attr(
    'value',
    value,
  )
}

EditView.prototype.disableCheckbox = function (box, message) {
  box
    .prop('disabled', true)
    .parent()
    .attr('data-tooltip', 'top')
    .data('tooltip', {
      disabled: false,
    })
    .attr('title', message)
  this.setImplicitCheckboxValue(box, box.prop('checked') ? '1' : '0')
  return this.checkboxAccessibleAdvisory(box).text(message)
}

EditView.prototype.enableCheckbox = function (box) {
  if (box.prop('disabled')) {
    if (this.assignment.inClosedGradingPeriod()) {
      return
    }
    box
      .prop('disabled', false)
      .parent()
      .timeoutTooltip()
      .timeoutTooltip('disable')
      .removeAttr('data-tooltip')
      .removeAttr('title')
    this.setImplicitCheckboxValue(box, '0')
    return this.checkboxAccessibleAdvisory(box).text('')
  }
}

EditView.prototype.handlesuppressFromGradebookChange = function () {
  return this.model.suppressAssignment(this.$suppressAssignment.prop('checked'))
}

EditView.prototype.handleGroupCategoryChange = function () {
  // clear any errors
  this.clearGroupSetErrors()
  const isGrouped = this.$groupCategoryBox.prop('checked')
  const isAnonymous = this.$anonymousGradingBox.prop('checked')
  if (isAnonymous) {
    this.$groupCategoryBox.prop('checked', false)
  } else if (isGrouped) {
    this.disableCheckbox(
      this.$allowAnnotatedDocument,
      I18n.t('Student annotation assignments are not currently supported for group assignments'),
    )
    this.disableCheckbox(
      this.$anonymousGradingBox,
      I18n.t('Anonymous grading cannot be enabled for group assignments'),
    )
  } else {
    this.enableCheckbox(this.$anonymousGradingBox)
    this.enableCheckbox(this.$allowAnnotatedDocument)
  }
  this.$intraGroupPeerReviews.toggleAccessibly(isGrouped)
  return this.togglePeerReviewsAndGroupCategoryEnabled()
}

EditView.prototype.handleAnonymousGradingChange = function () {
  const isGrouped = this.$groupCategoryBox.prop('checked')
  const isAnonymous = !isGrouped && this.$anonymousGradingBox.prop('checked')
  const isAnnotated = this.$allowAnnotatedDocument.prop('checked')
  this.assignment.anonymousGrading(isAnonymous)
  if (isGrouped) {
    return this.$anonymousGradingBox.prop('checked', false)
  } else if (this.assignment.anonymousGrading() || this.assignment.gradersAnonymousToGraders()) {
    return this.disableCheckbox(
      this.$groupCategoryBox,
      I18n.t('Group assignments cannot be enabled for anonymously graded assignments'),
    )
  } else if (!this.assignment.moderatedGrading()) {
    if (isAnnotated) {
      return this.disableCheckbox(
        this.$groupCategoryBox,
        I18n.t('Group assignments do not currently support student annotation assignments'),
      )
    } else if (this.model.canGroup()) {
      return this.enableCheckbox(this.$groupCategoryBox)
    }
  }
}

EditView.prototype.handlePostToSisBoxChange = function () {
  const postToSISChecked = this.$postToSisBox.prop('checked')
  this.model.set('post_to_sis', postToSISChecked)
}

EditView.prototype.handleHideZeroPointQuizChange = function () {
  if (this.$hideZeroPointQuizzesBox.prop('checked')) {
    this.$omitFromFinalGradeBox.prop('checked', true)
    return this.disableCheckbox(
      this.$omitFromFinalGradeBox,
      I18n.t(
        'This is enabled by default as assignments can not be withheld from the gradebook and still count towards it.',
      ),
    )
  } else {
    return this.enableCheckbox(this.$omitFromFinalGradeBox)
  }
}

EditView.prototype.togglePeerReviewsAndGroupCategoryEnabled = function () {
  if (this.assignment.moderatedGrading()) {
    this.disableCheckbox(
      this.$peerReviewsBox,
      I18n.t('Peer reviews cannot be enabled for moderated assignments'),
    )
    this.disableCheckbox(
      this.$groupCategoryBox,
      I18n.t('Group assignments cannot be enabled for moderated assignments'),
    )
  } else {
    this.enableCheckbox(this.$peerReviewsBox)
    if (this.model.canGroup()) {
      this.enableCheckbox(this.$groupCategoryBox)
    }
  }
  return this.renderModeratedGradingFormFieldGroup()
}

EditView.prototype.setDefaultsIfNew = function () {
  if (this.assignment.isNew()) {
    if (userSettings.contextGet('new_assignment_settings')) {
      each(
        this.settingsToCache(),
        (function (_this) {
          return function (setting) {
            let ref, setting_from_cache
            setting_from_cache = userSettings.contextGet('new_assignment_settings')[setting]
            if (setting_from_cache === '1' || setting_from_cache === '0') {
              setting_from_cache = parseInt(setting_from_cache, 10)
            }
            if (
              setting_from_cache &&
              (_this.assignment.get(setting) == null ||
                ((ref = _this.assignment.get(setting)) != null ? ref.length : void 0) === 0)
            ) {
              _this.assignment.set(setting, setting_from_cache)
            }
            if (setting_from_cache && setting === 'allowed_attempts') {
              setting_from_cache = parseInt(setting_from_cache, 10)
              if (Number.isNaN(setting_from_cache)) {
                setting_from_cache = -1
              }
              return _this.assignment.set(setting, setting_from_cache)
            }
          }
        })(this),
      )
    }
    if (this.assignment.submissionTypes().length === 0) {
      return this.assignment.submissionTypes(['online'])
    }
  }
}

EditView.prototype.cacheAssignmentSettings = function () {
  const new_assignment_settings = _.pick.apply(
    _,
    [this.getFormData()].concat(slice.call(this.settingsToCache())),
  )
  return userSettings.contextSet('new_assignment_settings', new_assignment_settings)
}

EditView.prototype.showTurnitinDialog = function (ev) {
  let model, type
  ev.preventDefault()
  type = 'turnitin'
  model = this.assignment.get('turnitin_settings')
  if (this.$vericiteEnabled.prop('checked')) {
    type = 'vericite'
    model = this.assignment.get('vericite_settings')
  }
  const turnitinDialog = new TurnitinSettingsDialog(model, type)
  return turnitinDialog.render().on(
    'settings:change',
    (function (_this) {
      return function (settings) {
        if (_this.$vericiteEnabled.prop('checked')) {
          _this.assignment.set('vericite_settings', new VeriCiteSettings(settings))
        } else {
          _this.assignment.set('turnitin_settings', new TurnitinSettings(settings))
        }
        turnitinDialog.off()
        return turnitinDialog.remove()
      }
    })(this),
  )
}

EditView.prototype.handleAssignmentSelectionSubmit = function (data) {
  // data comes in a funky format from SelectContentDialog,
  // so reconstruct it into a ResourceLinkContentItem
  const contentItem = {
    id: data['item[id]'],
    type: data['item[type]'],
    title: data['item[title]'],
    text: data['item[description]'],
    url: data['item[url]'],
    custom: tryJsonParse(data['item[custom_params]']),
    window: {
      targetName: data['item[new_tab]'] === '1' ? '_blank' : '_self',
    },
    iframe: {
      width: data['item[iframe][width]'],
      height: data['item[iframe][height]'],
    },
    lineItem: tryJsonParse(data['item[line_item]']),
    'https://canvas.instructure.com/lti/preserveExistingAssignmentName': tryJsonParse(
      data['item[preserveExistingAssignmentName]'],
    ),
  }
  this.handleContentItem(contentItem)
}

/**
 * Sets assignment values based on LTI 1.3 deep linking Content Item.
 * Values are stored in form fields that get rolled up in getFormData
 * when Save is clicked.
 * @param {ResourceLinkContentItem} item
 */
EditView.prototype.handleContentItem = function (item) {
  this.$externalToolsCustomParams.val(JSON.stringify(item.custom))
  this.$externalToolsContentType.val(item.type)
  this.$externalToolsContentId.val(item.id || this.selectedTool?.id)
  this.$externalToolsUrl.val(item.url)
  this.$externalToolsTitle.val(item.title)
  this.$externalToolsNewTab.prop('checked', item.window?.targetName === '_blank')
  this.$externalToolsIframeWidth.val(item.iframe?.width)
  this.$externalToolsIframeHeight.val(item.iframe?.height)

  const lineItem = item.lineItem
  if (lineItem) {
    this.$externalToolsLineItem.val(JSON.stringify(lineItem))
    if ('scoreMaximum' in lineItem) {
      this.$assignmentPointsPossible.val(lineItem.scoreMaximum)
    }
  }

  const newAssignmentName = lineItem && 'label' in lineItem ? lineItem.label : item.title
  const replaceAssignmentName =
    !item['https://canvas.instructure.com/lti/preserveExistingAssignmentName']
  if (newAssignmentName && (replaceAssignmentName || this.$name.val() === '')) {
    this.$name.val(newAssignmentName)
  }

  if (item.text) {
    RichContentEditor.callOnRCE(this.$description, 'set_code', item.text)
  }

  this.renderAssignmentSubmissionTypeContainer()

  // TODO: add date prefill here
}

EditView.prototype.setDefaultSubmissionTypeSelectionContentType = function () {
  return this.$externalToolsContentType.val(DEFAULT_SUBMISSION_TYPE_SELECTION_CONTENT_TYPE)
}

EditView.prototype.submissionTypeSelectionHasResource = function () {
  return this.$externalToolsContentType.val() !== DEFAULT_SUBMISSION_TYPE_SELECTION_CONTENT_TYPE
}

// used when loading an existing assignment with a resource link. otherwise
// this is set in deep linking response
EditView.prototype.setHasResourceLink = function () {
  return this.$externalToolsContentType.val('ltiResourceLink')
}

EditView.prototype.handleRemoveResource = function () {
  // Restore things to how they were before the user pushed the button to
  // launch the submission_type_selection tool
  this.setDefaultSubmissionTypeSelectionContentType()
  this.$externalToolsUrl.val(this.selectedTool.external_url)
  this.$externalToolsTitle.val('')
  this.$externalToolsCustomParams.val('')
  this.$externalToolsIframeWidth.val('')
  this.$externalToolsIframeHeight.val('')

  this.renderAssignmentSubmissionTypeContainer()
}

/**
 * Attempts to JSON.parse the input, returning undefined if
 * it's not possible
 * @param {string} jsonStr
 * @returns {unknown}
 */
function tryJsonParse(jsonStr) {
  try {
    return JSON.parse(jsonStr)
  } catch {
    return undefined
  }
}

EditView.prototype.showExternalToolsDialog = function () {
  return selectContentDialog({
    dialog_title: I18n.t('select_external_tool_dialog_title', 'Configure External Tool'),
    select_button_text: I18n.t('buttons.select_url', 'Select'),
    no_name_input: true,
    submit: data => {
      this.handleAssignmentSelectionSubmit(data)
    },
  })
}

EditView.prototype.clearAllowedExtensionsAndErrors = function () {
  this.getElement(ALLOWED_EXTENSIONS_INPUT_NAME).value = ''
  this.hideErrors('allowed_extensions_errors')
}

EditView.prototype.toggleRestrictFileUploads = function () {
  const fileUploadsAllowed = this.$allowFileUploads.prop('checked')
  if (fileUploadsAllowed) this.clearAllowedExtensionsAndErrors()
  return this.$restrictFileUploadsOptions.toggleAccessibly(fileUploadsAllowed)
}

EditView.prototype.toggleAnnotatedDocument = function () {
  this.hideErrors('online_submission_types[student_annotation]_errors')
  const isAnonymous = this.$anonymousGradingBox.prop('checked')
  this.$annotatedDocumentOptions.toggleAccessibly(this.$allowAnnotatedDocument.prop('checked'))
  if (this.$allowAnnotatedDocument.prop('checked')) {
    this.disableCheckbox(
      this.$groupCategoryBox,
      I18n.t('Group assignments do not currently support student annotation assignments'),
    )
    this.renderAnnotatedDocumentSelector()
    if (this.shouldRenderUsageRights()) {
      this.renderAnnotatedDocumentUsageRightsSelectBox()
    }
    return this.$allowAnnotatedDocumentInfo.show()
  } else {
    if (isAnonymous) {
      this.disableCheckbox(
        this.$groupCategoryBox,
        I18n.t('Group assignments cannot be enabled for anonymously graded assignments'),
      )
    } else if (this.model.canGroup()) {
      this.enableCheckbox(this.$groupCategoryBox)
    }
    this.unmountAnnotatedDocumentSelector()
    if (this.shouldRenderUsageRights()) {
      this.unmountAnnotatedDocumentUsageRightsSelectBox()
    }
    return this.$allowAnnotatedDocumentInfo.hide()
  }
}

EditView.prototype.getAnnotatedDocumentContainer = function () {
  return document.querySelector('#annotated_document_chooser_container')
}

EditView.prototype.setAnnotatedDocument = function (file) {
  const $annotatableAttachmentInput = document.getElementById('annotatable_attachment_id')
  this.annotatedDocument = file
  if (this.annotatedDocument === null) {
    return ($annotatableAttachmentInput.value = '')
  } else {
    return ($annotatableAttachmentInput.value = this.annotatedDocument.id)
  }
}

EditView.prototype.getAnnotatedDocument = function () {
  return this.annotatedDocument
}

EditView.prototype.renderAnnotatedDocumentSelector = function () {
  this.hideErrors('online_submission_types[student_annotation]_errors')
  const props = {
    attachment: this.getAnnotatedDocument(),
    defaultUploadFolderId: ENV.ROOT_FOLDER_ID,
    onRemove: (function (_this) {
      return function (fileInfo) {
        $.screenReaderFlashMessageExclusive(
          I18n.t('removed %{filename}', {
            filename: fileInfo.name,
          }),
        )
        _this.setAnnotatedDocument(null)
        _this.renderAnnotatedDocumentSelector()
        if (_this.shouldRenderUsageRights()) {
          return _this.renderAnnotatedDocumentUsageRightsSelectBox()
        }
      }
    })(this),
    onSelect: (function (_this) {
      return function (fileInfo) {
        $.screenReaderFlashMessageExclusive(
          I18n.t('selected %{filename}', {
            filename: fileInfo.name,
          }),
        )
        const match = fileInfo.src.match(/\/(\w+)\/(\d+)\/files\/.*/)
        _this.setAnnotatedDocument({
          id: fileInfo.id,
          name: fileInfo.name,
          contextType: match[1],
          contextId: match[2],
        })
        _this.renderAnnotatedDocumentSelector()
        if (_this.shouldRenderUsageRights()) {
          return _this.renderAnnotatedDocumentUsageRightsSelectBox()
        }
      }
    })(this),
  }
  const element = React.createElement(AnnotatedDocumentSelector, props)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(element, this.getAnnotatedDocumentContainer())
}

EditView.prototype.unmountAnnotatedDocumentSelector = function () {
  ReactDOM.unmountComponentAtNode(this.getAnnotatedDocumentContainer())
  return this.setAnnotatedDocument(null)
}

EditView.prototype.shouldRenderUsageRights = function () {
  return ENV.USAGE_RIGHTS_REQUIRED
}

EditView.prototype.setAnnotatedDocumentUsageRights = function (usageRights) {
  this.annotatedDocumentUsageRights = usageRights
  if (this.annotatedDocumentUsageRights === null) {
    return
  }
  $(USAGE_RIGHTS_SELECTOR)
    .val(this.annotatedDocumentUsageRights.use_justification)
    .trigger('change')
  $(USAGE_RIGHTS_SELECTOR)
    .get(0)
    .dispatchEvent(
      new Event('change', {
        bubbles: true,
      }),
    )
  if ($(CREATIVE_COMMONS_SELECTION).length) {
    $(CREATIVE_COMMONS_SELECTION).val(this.annotatedDocumentUsageRights.license)
  }
  return $(COPYRIGHT_HOLDER).val(this.annotatedDocumentUsageRights.legal_copyright)
}

EditView.prototype.getAnnotatedDocumentUsageRights = function () {
  const useJustification = $(USAGE_RIGHTS_SELECTOR).val()
  const annotatedDocumentUsageRights = {}
  annotatedDocumentUsageRights.use_justification = useJustification
  this.$creativeCommonsSelection = $('' + CREATIVE_COMMONS_SELECTION)
  if (useJustification === 'creative_commons' && this.$creativeCommonsSelection.length) {
    annotatedDocumentUsageRights.license = this.$creativeCommonsSelection.val()
  }
  annotatedDocumentUsageRights.legal_copyright = $(COPYRIGHT_HOLDER).val()
  return annotatedDocumentUsageRights
}

EditView.prototype.fetchAttachmentFile = function (fileId, callback, errorCallback) {
  const baseUrl = '/api/v1/files/' + fileId
  const params = {
    include: ['usage_rights'],
  }
  const url = baseUrl + '?' + param(params)
  return $.getJSON(url)
    .pipe(function (response) {
      return callback(response)
    })
    .fail(function () {
      return errorCallback()
    })
}

EditView.prototype.renderAnnotatedDocumentUsageRightsSelectBox = function () {
  let contextId, contextType, self
  const annotatedDocument = this.getAnnotatedDocument()
  if (annotatedDocument) {
    contextType = annotatedDocument.contextType
    contextId = annotatedDocument.contextId
    const clearUsageRightsErrors = () => {
      $(document).trigger('validateUsageRightsSelectedValue', {error: false})
      this.hideErrors('usage_rights_use_justification_errors')
    }
    ReactDOM.render(
      React.createElement(UsageRightsSelectBox, {
        contextType,
        contextId,
        hideErrors: clearUsageRightsErrors,
      }),
      document.querySelector(USAGE_RIGHTS_CONTAINER),
    )
    $(USAGE_RIGHTS_CONTAINER + ' .UsageRightsSelectBox__container').addClass('edit-view')
    self = this
    return this.fetchAttachmentFile(
      annotatedDocument.id,
      function (document) {
        return self.setAnnotatedDocumentUsageRights(document.usage_rights)
      },
      function () {
        const message = I18n.t('Failed to load student annotation file data.')
        $.flashError(message)
        return $.screenReaderFlashMessage(message)
      },
    )
  } else if (this.shouldRenderUsageRights()) {
    return this.unmountAnnotatedDocumentUsageRightsSelectBox()
  }
}

EditView.prototype.unmountAnnotatedDocumentUsageRightsSelectBox = function () {
  ReactDOM.unmountComponentAtNode(document.querySelector(USAGE_RIGHTS_CONTAINER))
  return this.setAnnotatedDocumentUsageRights(null)
}

EditView.prototype.toggleAdvancedTurnitinSettings = function (ev) {
  ev.preventDefault()
  return this.$advancedTurnitinSettings.toggleAccessibly(
    this.$turnitinEnabled.prop('checked') || this.$vericiteEnabled.prop('checked'),
  )
}

EditView.prototype.defaultExternalToolEnabled = function () {
  return !!this.defaultExternalToolUrl()
}

EditView.prototype.defaultExternalToolUrl = function () {
  return ENV.DEFAULT_ASSIGNMENT_TOOL_URL
}

EditView.prototype.defaultExternalToolName = function () {
  return ENV.DEFAULT_ASSIGNMENT_TOOL_NAME
}

EditView.prototype.renderDefaultExternalTool = function () {
  const props = {
    toolDialog: $('#resource_selection_dialog'),
    courseId: ENV.COURSE_ID,
    toolUrl: this.defaultExternalToolUrl(),
    toolName: this.defaultExternalToolName(),
    toolButtonText: ENV.DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT,
    toolInfoMessage: ENV.DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE,
    previouslySelected: this.assignment.defaultToolSelected(),
    hideErrors: this.hideErrors,
  }
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(
    React.createElement(DefaultToolForm, props),
    document.querySelector('[data-component="DefaultToolForm"]'),
  )
}

EditView.prototype.handleRestrictFileUploadsChange = function () {
  const fileUploadsRestricted = this.$restrictFileUploads.prop('checked')
  if (fileUploadsRestricted) this.clearAllowedExtensionsAndErrors()
  return this.$allowedExtensions.toggleAccessibly(fileUploadsRestricted)
}

EditView.prototype.handleGradingTypeChange = function (gradingType) {
  this.$gradedAssignmentFields.toggleAccessibly(gradingType !== 'not_graded')
  return this.handleSubmissionTypeChange(null)
}

EditView.prototype.hasMasteryConnectData = function () {
  // Some places check for this data before clearing/overwriting...
  // It's not clear the reasoning behind this, but I'm for leaving as-is for now.
  // If some of the resulting odd behavior (switching to MasteryCoinnect from another submission type placement tool) surfaces, revisit with Mastery Connect team (git ref ef3249f62f)
  return !!this.$externalToolExternalData.val()
}

EditView.prototype.handleSubmissionTypeChange = function (_ev) {
  if (this.$submissionType.length === 0) return
  const subVal = this.$submissionType.val()
  this.$onlineSubmissionTypes.toggleAccessibly(subVal === 'online')
  this.$externalToolSettings.toggleAccessibly(subVal === 'external_tool')
  if (subVal === 'external_tool' && this.$peerReviewsBox.prop('checked')) {
    this.$peerReviewsBox.prop('checked', false)
    this.togglePeerReviewsAndGroupCategoryEnabled()
    $('#peer_reviews_details')?.toggleAccessibly(false)
  }
  const isPlacementTool = subVal.includes('external_tool_placement')
  this.$externalToolPlacementLaunchContainer.toggleAccessibly(isPlacementTool)

  if (isPlacementTool) {
    this.handlePlacementExternalToolSelect(subVal)
  } else if (this.selectedTool && subVal === 'external_tool' && !this.hasMasteryConnectData()) {
    // Moving from a submission_type_placement tool to generic
    // "External Tool" type: empty out the fields. this prevents people
    // from working around the "require_resource_selection" field just
    // by choosing the tool and then choosing "External Tool"
    this.handleRemoveResource()
    this.$externalToolsUrl.val('')
    this.selectedTool = undefined
  }
  this.$groupCategorySelector.toggleAccessibly(subVal !== 'external_tool' && !isPlacementTool)
  this.$peerReviewsFields.toggleAccessibly(subVal !== 'external_tool' && !isPlacementTool)
  this.$defaultExternalToolContainer.toggleAccessibly(subVal === 'default_external_tool')
  this.$allowedAttemptsContainer.toggleAccessibly(
    subVal === 'online' || subVal === 'external_tool' || isPlacementTool,
  )
  this.handleOnlineSubmissionTypeChange()
  return this.$externalToolNewTabContainer.toggleAccessibly(subVal.includes('external_tool'))
}

EditView.prototype.validateGuidData = function (event) {
  const data = event.data.data

  // If data is a string, convert it to an array for consistent processing
  const dataArray = Array.isArray(data) ? data : [data]
  const regexPattern =
    /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/

  for (const str of dataArray) {
    if (!regexPattern.test(str)) {
      return false
    }
  }
  return dataArray
}

EditView.prototype.handleMessageEvent = function (event) {
  if (event?.data?.subject !== 'assignment.set_ab_guid') {
    return
  }
  const abGuid = this.validateGuidData(event)
  if (abGuid) {
    this.assignment.set('ab_guid', abGuid)
  }
}

EditView.prototype.handlePlacementExternalToolSelect = function (selection) {
  const toolId = selection.replace('external_tool_placement_', '')
  this.$externalToolsContentId.val(toolId)
  this.setDefaultSubmissionTypeSelectionContentType()
  this.selectedTool = find(this.model.submissionTypeSelectionTools(), function (tool) {
    return toolId === tool.id
  })

  const toolIdsMatch = toolId === this.assignment.selectedSubmissionTypeToolId()
  const extToolUrlsMatch = this.$externalToolsUrl.val() === this.assignment.externalToolUrl()

  if (!this.hasMasteryConnectData() && !(toolIdsMatch && extToolUrlsMatch)) {
    // When switching to a submission_type_selection tool in the dropdown, set
    // the URL of the tool. Don't set if we are just editing the assignment
    // (toolIdsMatch and extToolUrlsMatch).

    this.$externalToolsUrl.val(this.selectedTool.external_url)
    // Ensure that custom params & other stuff left over from another previous
    // deep link response get cleared out when the user chooses a tool:
    this.$externalToolsCustomParams.val('')
    this.$externalToolsIframeWidth.val('')
    this.$externalToolsIframeHeight.val('')
    this.$externalToolsTitle.val('')
  } else if (this.assignment.resourceLink()) {
    this.setHasResourceLink()
    if (this.assignment.resourceLink().title) {
      this.$externalToolsTitle.val(this.assignment.resourceLink().title)
    }
  }

  this.renderAssignmentSubmissionTypeContainer()
}

EditView.prototype.renderAssignmentSubmissionTypeContainer = function () {
  const resource = this.submissionTypeSelectionHasResource()
    ? {title: this.$externalToolsTitle.val()}
    : undefined

  const props = {
    tool: this.selectedTool,
    resource,
    onRemoveResource: this.handleRemoveResource,
    onLaunchButtonClick: this.handleSubmissionTypeSelectionLaunch,
  }

  ReactDOM.render(
    React.createElement(AssignmentSubmissionTypeContainer, props),
    document.querySelector('[data-component="AssignmentSubmissionTypeContainer"]'),
  )
}

EditView.prototype.handleSubmissionTypeSelectionLaunch = function () {
  // clear any errors
  this.hideErrors(`${SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON}_errors`)
  const removeListener = addDeepLinkingListener(event => {
    if (event.data.content_items?.length >= 1) {
      this.handleContentItem(event.data.content_items[0])
    }

    removeListener()
    this.handleSubmissionTypeSelectionDialogClose()
  })

  return this.renderSubmissionTypeSelectionDialog(true)
}

EditView.prototype.handleSubmissionTypeSelectionDialogClose = function () {
  return this.renderSubmissionTypeSelectionDialog(false)
}

EditView.prototype.renderSubmissionTypeSelectionDialog = function (open) {
  const contextInfo = ENV.context_asset_string.split('_')
  const contextType = contextInfo[0]
  const contextId = parseInt(contextInfo[1], 10)
  const props = {
    tool: {
      definition_id: this.selectedTool.id,
      placements: {
        submission_type_selection: {
          launch_width: this.selectedTool.selection_width,
          launch_height: this.selectedTool.selection_height,
        },
      },
    },
    title: this.selectedTool.title,
    isOpen: open,
    onRequestClose: this.handleSubmissionTypeSelectionDialogClose,
    contextType,
    contextId,
    launchType: 'submission_type_selection',
    onExternalContentReady: this.handleExternalContentReady,
  }
  const mountPoint = document.querySelector('#assignment_submission_type_selection_tool_dialog')
  const dialog = React.createElement(ExternalToolModalLauncher, props)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(dialog, mountPoint)
}

EditView.prototype.handleExternalContentReady = function (data) {
  if (!data.contentItems || data.contentItems.length === 0) {
    return
  }
  let student_count_text
  const item = data.contentItems[0]
  this.$externalToolsUrl.val(item.url)
  this.$externalToolsTitle.val(item.title)
  if (item.title) {
    this.$name.val(item.title)
  }
  const mc_ext = item[LTI_EXT_MASTERY_CONNECT]
  if (mc_ext) {
    mc_ext.key = LTI_EXT_MASTERY_CONNECT
    this.$assignmentPointsPossible.val(mc_ext.points)
    this.$externalToolExternalData.val(JSON.stringify(mc_ext))
    $('#mc_external_data_assessment').text(item.title)
    $('#mc_external_data_points').text(mc_ext.points + ' ' + I18n.t('points'))
    $('#mc_external_data_objectives').text(mc_ext.objectives)
    $('#mc_external_data_tracker').text(mc_ext.trackerName)
    $('#mc_external_data_tracker_alignment').text(mc_ext.trackerAlignment)
    student_count_text = I18n.t(
      {
        zero: '0 Students',
        one: '1 Student',
        other: '%{count} Students',
      },
      {
        count: mc_ext.studentCount,
      },
    )
    $('#mc_external_data_students').text(student_count_text)
    return showFlashAlert({
      message: I18n.t('Assignment details updated'),
      type: 'info',
    })
  }
}

EditView.prototype.handleOnlineSubmissionTypeChange = function (_env) {
  const showAssetProcessors =
    window.ENV?.FEATURES?.lti_asset_processor &&
    this.$submissionType.val() === 'online' &&
    (this.$onlineSubmissionTypes.find(ALLOW_FILE_UPLOADS).prop('checked') ||
      this.$onlineSubmissionTypes.find(ALLOW_TEXT_ENTRY).prop('checked'))
  this.$assetProcessorsContainer.toggleAccessibly(showAssetProcessors)

  const showConfigTools =
    ENV.PLAGIARISM_DETECTION_PLATFORM &&
    this.$submissionType.val() === 'online' &&
    (this.$onlineSubmissionTypes.find(ALLOW_FILE_UPLOADS).prop('checked') ||
      this.$onlineSubmissionTypes.find(ALLOW_TEXT_ENTRY).prop('checked'))
  return this.$similarityDetectionTools.toggleAccessibly(
    showConfigTools && ENV.PLAGIARISM_DETECTION_PLATFORM,
  )
}

EditView.prototype.afterRender = function () {
  this.$peerReviewsBox = $('' + PEER_REVIEWS_BOX)
  this.$intraGroupPeerReviews = $('' + INTRA_GROUP_PEER_REVIEWS)
  this.$groupCategoryBox = $('' + GROUP_CATEGORY_BOX)
  this.$anonymousGradingBox = $('' + ANONYMOUS_GRADING_BOX)
  this.renderModeratedGradingFormFieldGroup()
  this.renderAllowedAttempts()
  // this.renderEnhancedRubrics()
  this.$graderCommentsVisibleToGradersBox = $('#assignment_grader_comment_visibility')
  this.$gradersAnonymousToGradersLabel = $('label[for="assignment_graders_anonymous_to_graders"]')
  if (this.$similarityDetectionTools.length > 0) {
    this.similarityDetectionTools = SimilarityDetectionTools.attach(
      this.$similarityDetectionTools.get(0),
      parseInt(ENV.COURSE_ID, 10),
      this.$secureParams.val(),
      parseInt(ENV.SELECTED_CONFIG_TOOL_ID, 10),
      ENV.SELECTED_CONFIG_TOOL_TYPE,
      ENV.REPORT_VISIBILITY_SETTING,
    )
  }
  if (this.$assignmentExternalTools.length > 0) {
    this.AssignmentExternalTools = AssignmentExternalTools.attach(
      this.$assignmentExternalTools.get(0),
      'assignment_edit',
      parseInt(ENV.COURSE_ID, 10),
      parseInt(this.assignment.id, 10),
    )
  }
  if (window.ENV?.FEATURES?.lti_asset_processor && this.$assetProcessorsContainer.length > 0) {
    assetProcessorsAttach({
      container: this.$assetProcessorsContainer.get(0),
      courseId: ENV.COURSE_ID,
      secureParams: this.$secureParams.val(),
      initialAttachedProcessors: ENV.ASSET_PROCESSORS || [],
      hideErrors: () => {
        this.hideErrors('asset_processors_errors')
      },
    })
  }

  this._attachEditorToDescription()
  this.togglePeerReviewsAndGroupCategoryEnabled()
  this.handleSubmissionTypeChange()
  this.handleGroupCategoryChange()
  this.handleAnonymousGradingChange()
  this.$hideZeroPointQuizzesOption.toggleAccessibly(this.$assignmentPointsPossible.val() === '0')
  this.handleHideZeroPointQuizChange()
  if (ENV.ANNOTATED_DOCUMENT) {
    this.setAnnotatedDocument({
      id: ENV.ANNOTATED_DOCUMENT.id,
      name: ENV.ANNOTATED_DOCUMENT.display_name,
      contextType: pluralize(ENV.ANNOTATED_DOCUMENT.context_type).toLowerCase(),
      contextId: ENV.ANNOTATED_DOCUMENT.context_id,
    })
  }
  if (this.$allowAnnotatedDocument.prop('checked')) {
    this.renderAnnotatedDocumentSelector()
  }
  if (this.$allowAnnotatedDocument.prop('checked')) {
    this.$allowAnnotatedDocumentInfo.show()
  } else {
    this.$allowAnnotatedDocumentInfo.hide()
  }
  if (this.shouldRenderUsageRights()) {
    this.renderAnnotatedDocumentUsageRightsSelectBox()
  }
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    this.conditionalReleaseEditor = ConditionalRelease.attach(
      this.$conditionalReleaseTarget.get(0),
      I18n.t('assignment'),
      ENV.CONDITIONAL_RELEASE_ENV,
    )
  }
  if (this.assignment.inClosedGradingPeriod()) {
    this.disableFields()
  }
  if (this.defaultExternalToolEnabled()) {
    this.renderDefaultExternalTool()
  }
  return this
}

EditView.prototype.toJSON = function () {
  const data = this.assignment.toView()
  return Object.assign(data, {
    assignment_attempts:
      typeof ENV !== 'undefined' && ENV !== null ? ENV.assignment_attempts_enabled : void 0,
    kalturaEnabled:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.KALTURA_ENABLED : void 0) || false,
    postToSISEnabled:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.POST_TO_SIS : void 0) || false,
    postToSISName: ENV.SIS_NAME,
    isLargeRoster:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0) || false,
    conditionalReleaseServiceEnabled:
      (typeof ENV !== 'undefined' && ENV !== null
        ? ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        : void 0) || false,
    coursePaceWithMasteryPath:
      (typeof ENV !== 'undefined' && ENV !== null
        ? ENV.IN_PACED_COURSE &&
          ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED &&
          ENV.FEATURES.course_pace_pacing_with_mastery_paths
        : void 0) || false,
    lockedItems: this.lockedItems,
    cannotEditGrades: this.cannotEditGrades,
    anonymousGradingEnabled:
      (typeof ENV !== 'undefined' && ENV !== null
        ? this.assignment.isQuizLTIAssignment() && !ENV.NEW_QUIZZES_ANONYMOUS_GRADING_ENABLED
          ? void 0
          : ENV.ANONYMOUS_GRADING_ENABLED
        : void 0) || false,
    anonymousInstructorAnnotationsEnabled:
      (typeof ENV !== 'undefined' && ENV !== null
        ? ENV.ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED
        : void 0) || false,
    is_horizon_course: !!ENV.horizon_course,
  })
}

EditView.prototype._attachEditorToDescription = function () {
  if (this.lockedItems.content) {
    return
  }
  return RichContentEditor.loadNewEditor(this.$description, {
    focus: true,
    manageParent: true,
    resourceType: 'assignment.body',
    resourceId: this.assignment.id,
  })
}

// -- Data for Submitting --
EditView.prototype._datesDifferIgnoringSeconds = function (newDate, originalDate) {
  const newWithoutSeconds = new Date(newDate)
  const originalWithoutSeconds = new Date(originalDate)
  // Since a user can't edit the seconds field in the UI and the form also
  // thinks that the seconds is always set to 00, we compare by everything
  // except seconds.
  originalWithoutSeconds.setSeconds(0)
  newWithoutSeconds.setSeconds(0)
  return originalWithoutSeconds.getTime() !== newWithoutSeconds.getTime()
}

EditView.prototype._adjustDateValue = function (newDate, originalDate) {
  // If the minutes value of the due date is 59, set the seconds to 59 so
  // the assignment ends up due one second before the following hour.
  // Otherwise, set it to 0 seconds.
  //
  // If the user has not changed the due date, don't touch the seconds value
  // (so that we don't clobber a due date set by the API).
  if (!newDate) {
    return null
  }
  const adjustedDate = new Date(newDate)
  originalDate = new Date(originalDate)
  if (this._datesDifferIgnoringSeconds(adjustedDate, originalDate)) {
    adjustedDate.setSeconds(adjustedDate.getMinutes() === 59 ? 59 : 0)
  } else {
    adjustedDate.setSeconds(originalDate.getSeconds())
  }
  return adjustedDate.toISOString()
}

EditView.prototype.getFormData = function () {
  let data
  data = EditView.__super__.getFormData.apply(this, arguments)
  data.submission_type = this.toolSubmissionType(data.submission_type)
  data = this._inferSubmissionTypes(data)
  data = this._filterAllowedExtensions(data)
  data = this._unsetGroupsIfExternalTool(data)
  data.ab_guid = this.assignment.get('ab_guid')
  if (
    this.groupCategorySelector &&
    !(typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0)
  ) {
    data = this.groupCategorySelector.filterFormData(data)
  }
  if (!data.post_to_sis) {
    data.post_to_sis = false
  }
  const defaultDates = this.dueDateOverrideView.getDefaultDueDate()
  if (defaultDates != null) {
    data.due_at = this._adjustDateValue(defaultDates.get('due_at'), this.model.dueAt())
    data.lock_at = this._adjustDateValue(defaultDates.get('lock_at'), this.model.lockAt())
    data.unlock_at = this._adjustDateValue(defaultDates.get('unlock_at'), this.model.unlockAt())
  } else {
    data.due_at = null
    data.lock_at = null
    data.unlock_at = null
  }

  if (data.peer_reviews_assign_at) {
    data.peer_reviews_assign_at = unfudgeDateForProfileTimezone(data.peer_reviews_assign_at)
  }

  if (ENV.COURSE_PACE_ENABLED && ENV.FEATURES.course_pace_pacing_with_mastery_paths) {
    data.assignment_overrides = this.masteryPathToggleView.getOverrides()
    data.only_visible_to_overrides = this.masteryPathToggleView.setOnlyVisibleToOverrides()
  } else {
    data.assignment_overrides = this.dueDateOverrideView.getOverrides()
    data.only_visible_to_overrides = this.dueDateOverrideView.setOnlyVisibleToOverrides()
  }

  if (this.shouldPublish) {
    data.published = true
  }
  if (data.points_possible) {
    data.points_possible = round(numberHelper.parse(data.points_possible), 2)
  }
  if (data.peer_review_count) {
    data.peer_review_count = numberHelper.parse(data.peer_review_count)
  }
  const $grader_count = $('#grader_count')
  // The custom_params are stored as a JSONified string in a hidden input, but the API uses an
  // actual JSON object, so we have to convert.
  if (data.external_tool_tag_attributes.custom_params.trim()) {
    data.external_tool_tag_attributes.custom_params = tryJsonParse(
      data.external_tool_tag_attributes.custom_params,
    )
  }
  if (data.external_tool_tag_attributes.line_item.trim()) {
    data.external_tool_tag_attributes.line_item = tryJsonParse(
      data.external_tool_tag_attributes.line_item,
    )
  }

  data.asset_processors = data.asset_processors?.map(tryJsonParse)

  if ($grader_count.length > 0) {
    data.grader_count = numberHelper.parse($grader_count[0].value)
  }
  return data
}

EditView.prototype.saveFormData = function () {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    return EditView.__super__.saveFormData.apply(this, arguments).pipe(
      (function (_this) {
        return function (data, status, xhr) {
          _this.conditionalReleaseEditor.updateAssignment(data)
          return _this.conditionalReleaseEditor.save().pipe(
            function () {
              return new $.Deferred().resolve(data, status, xhr).promise()
            },
            function (err) {
              return new $.Deferred().reject(xhr, err).promise()
            },
          )
        }
      })(this),
    )
  } else {
    return EditView.__super__.saveFormData.apply(this, arguments)
  }
}

EditView.prototype.submit = function (event) {
  let missingDateDialog
  event.preventDefault()
  event.stopPropagation()
  this.cacheAssignmentSettings()
  if (
    (ENV.ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS ||
      !this.dueDateOverrideView.containsDiffTagOverrides()) &&
    this.dueDateOverrideView.containsSectionsWithoutOverrides()
  ) {
    missingDateDialog = new MissingDateDialog({
      success: (function (_this) {
        return function (dateDialog) {
          dateDialog.dialog('close').remove()
          return ValidatedFormView.prototype.submit.call(_this)
        }
      })(this),
    })
    missingDateDialog.cancel = function (_e) {
      return missingDateDialog.$dialog.dialog('close').remove()
    }
    return missingDateDialog.render()
  } else {
    return EditView.__super__.submit.apply(this, arguments)
  }
}

EditView.prototype.toolSubmissionType = function (submissionType) {
  if (
    submissionType === 'default_external_tool' ||
    submissionType.includes('external_tool_placement')
  ) {
    return 'external_tool'
  } else {
    return submissionType
  }
}

EditView.prototype.saveAndPublish = function (event) {
  this.shouldPublish = true
  this.disableWhileLoadingOpts = {
    buttons: ['.save_and_publish'],
  }
  this.preventBuildNavigation = true
  return this.submit(event)
}

EditView.prototype.handleSave = function (event) {
  this.preventBuildNavigation = true
  return this.submit(event)
}

EditView.prototype.onSaveFail = function (xhr) {
  this.shouldPublish = false
  this.disableWhileLoadingOpts = {}
  return EditView.__super__.onSaveFail.call(this, xhr)
}

EditView.prototype._inferSubmissionTypes = function (assignmentData) {
  let types
  if (assignmentData.grading_type === 'not_graded') {
    assignmentData.submission_types = ['not_graded']
  } else if (assignmentData.submission_type === 'online') {
    types = filter(keys(assignmentData.online_submission_types), function (k) {
      return assignmentData.online_submission_types[k] === '1'
    })
    assignmentData.submission_types = types
  } else {
    assignmentData.submission_types = [assignmentData.submission_type]
  }
  delete assignmentData.online_submission_type
  delete assignmentData.online_submission_types
  return assignmentData
}

EditView.prototype._filterAllowedExtensions = function (data) {
  const restrictFileExtensions = data.restrict_file_extensions
  delete data.restrict_file_extensions
  const allowFileUploads = this.$allowFileUploads.prop('checked')
  if (restrictFileExtensions === '1' && allowFileUploads) {
    data.allowed_extensions = filter(data.allowed_extensions.split(','), function (ext) {
      return $.trim(ext.toString()).length > 0
    })
  } else {
    data.allowed_extensions = null
  }
  return data
}

EditView.prototype._unsetGroupsIfExternalTool = function (data) {
  if (data.submission_type === 'external_tool') {
    data.group_category_id = null
  }
  return data
}

// Pre-Save Validations
EditView.prototype.fieldSelectors = Object.assign(
  AssignmentGroupSelector.prototype.fieldSelectors,
  GroupCategorySelector.prototype.fieldSelectors,
  {
    grader_count: '#grader_count',
  },
  {
    usage_rights_use_justification: USAGE_RIGHTS_SELECTOR,
  },
  {
    usage_rights_legal_copyright: COPYRIGHT_HOLDER,
  },
  {
    asset_processors: '#asset_processors_container',
  },
)

EditView.prototype.showErrors = function (errors) {
  errors = this.sortErrorsByVerticalScreenPosition(errors)
  let shouldFocus = true
  Object.entries(errors).forEach(([key, value]) => {
    // For this to function properly
    // the error containers must have an ID formatted as ${key}_errors.
    const errorsContainerID = `${key}_errors`
    const errorsContainer = document.getElementById(errorsContainerID)
    if (errorsContainer) {
      const root = this.errorRoots[errorsContainerID] ?? createRoot(errorsContainer)
      const noMargin = [
        'allowed_attempts',
        'final_grader_id',
        'grader_count',
        ONLINE_SUBMISSION_CHECKBOXES_GROUP,
        SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON,
      ].includes(key)
      const marginTop = [
        EXTERNAL_TOOL_URL_INPUT_NAME,
        ASSIGNMENT_NAME_INPUT_NAME,
        POINTS_POSSIBLE_INPUT_NAME,
        ALLOWED_EXTENSIONS_INPUT_NAME,
        GROUP_CATEGORY_SELECT,
        DEFAULT_TOOL_LAUNCH_BUTTON,
      ].includes(key)
      root.render(
        <FormattedErrorMessage
          message={value[0].message}
          margin={noMargin ? '0' : marginTop ? 'xx-small 0 0 0' : '0 0 0 medium'}
          iconMargin={value[0].longMessage ? '0 xx-small medium 0' : '0 xx-small xxx-small 0'}
        />,
      )
      this.errorRoots[errorsContainerID] = root
      delete errors[key]
      const element = this.getElement(key)
      if (element) {
        element.setAttribute('aria-describedby', errorsContainerID)

        if (
          [
            EXTERNAL_TOOL_URL_INPUT_NAME,
            ASSIGNMENT_NAME_INPUT_NAME,
            POINTS_POSSIBLE_INPUT_NAME,
            ALLOWED_EXTENSIONS_INPUT_NAME,
            GROUP_CATEGORY_SELECT,
            DEFAULT_TOOL_LAUNCH_BUTTON,
            SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON,
            USAGE_RIGHTS_SELECT,
          ].includes(key)
        ) {
          const selector =
            key === EXTERNAL_TOOL_URL_INPUT_NAME
              ? 'assignment_external_tool_tag_attributes_url_container'
              : key
          this.getElement(selector)?.classList.add('error-outline')
        }

        if (shouldFocus) {
          element.focus()
          shouldFocus = false
        }
      }

      if (key === ASSIGNMENT_NAME_INPUT_NAME) {
        document.getElementById('assignment_name_asterisk')?.classList.add('error-text')
      }

      if (key === ONLINE_SUBMISSION_CHECKBOXES_GROUP) {
        document.getElementById('online_entry_options_asterisk')?.classList.add('error-text')
      }
    }
  })

  // override view handles displaying override errors, remove them
  // before calling super
  delete errors.assignmentOverrides
  EditView.__super__.showErrors.call(this, errors)
  this.trigger('show-errors', errors)
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    if (errors.conditional_release) {
      return this.conditionalReleaseEditor.focusOnError()
    }
  }
}

EditView.prototype.sortErrorsByVerticalScreenPosition = function (errors) {
  return Object.entries(errors)
    .map(([errorKey, errorMessage]) => {
      const errorElement = this.getElement(errorKey)
      if (!errorElement) return null

      const elementRect = errorElement.getBoundingClientRect()
      const verticalPosition = elementRect.top + window.scrollY
      return {errorKey, errorMessage, verticalPosition}
    })
    .filter(errorEntry => errorEntry !== null)
    .sort((firstError, secondError) => firstError.verticalPosition - secondError.verticalPosition)
    .reduce((sortedErrors, errorEntry) => {
      sortedErrors[errorEntry.errorKey] = errorEntry.errorMessage
      return sortedErrors
    }, {})
}

EditView.prototype.getElement = function (key) {
  const byId = document.getElementById(key)
  if (byId) return byId

  // This check is necessary because some elements may share the same name attribute
  // but have the `hidden` attribute set.
  // These hidden elements should be excluded from the selection to ensure
  // we only target visible elements in the DOM.
  const byName = document.querySelector(`[name="${key}"]:not([type="hidden"])`)
  if (byName) return byName

  const byCustomSelector = document.querySelector(EditView.prototype.fieldSelectors[key])
  if (byCustomSelector) return byCustomSelector

  return null
}

EditView.prototype.clearErrorsOnInput = function (event) {
  const key = event.target.name
  this.hideErrors(`${key}_errors`)
}

EditView.prototype.hideErrors = function (containerId) {
  if (containerId) {
    this.errorRoots[containerId]?.unmount()
    delete this.errorRoots[containerId]

    const key = containerId.replace(/_errors$/, '')
    if (
      [
        EXTERNAL_TOOL_URL_INPUT_NAME,
        ASSIGNMENT_NAME_INPUT_NAME,
        POINTS_POSSIBLE_INPUT_NAME,
        ALLOWED_EXTENSIONS_INPUT_NAME,
        GROUP_CATEGORY_SELECT,
        SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON,
        USAGE_RIGHTS_SELECT,
      ].includes(key)
    ) {
      const selector =
        key === EXTERNAL_TOOL_URL_INPUT_NAME
          ? 'assignment_external_tool_tag_attributes_url_container'
          : key
      const element = this.getElement(selector)
      element?.classList.remove('error-outline')
    }
    if (key === ASSIGNMENT_NAME_INPUT_NAME) {
      document.getElementById('assignment_name_asterisk')?.classList.remove('error-text')
    }
  }
}

EditView.prototype.validateBeforeSave = function (data, errors) {
  let crErrors
  errors = this._validateTitle(data, errors)
  errors = this._validateSubmissionTypes(data, errors)
  errors = this._validateAllowedExtensions(data, errors)
  errors = this.assignmentGroupSelector.validateBeforeSave(data, errors)
  Object.assign(errors, this.validateFinalGrader(data))
  Object.assign(errors, this.validateGraderCount(data))
  if (
    this.groupCategorySelector &&
    !(typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0)
  ) {
    errors = this.groupCategorySelector.validateBeforeSave(data, errors)
  }
  errors = this._validatePointsPossible(data, errors)
  errors = this._validateExternalTool(data, errors)
  errors = this._validateAllowedAttempts(data, errors)
  const data2 = {
    assignment_overrides: this.dueDateOverrideView.getAllDates(),
    postToSIS: data.post_to_sis === '1',
  }
  errors = this.dueDateOverrideView.validateBeforeSave(data2, errors)
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    crErrors = this.conditionalReleaseEditor.validateBeforeSave()
    if (crErrors) {
      errors.conditional_release = crErrors
    }
  }
  const sectionViewRef = document.getElementById(
    'manage-assign-to-container',
  )?.reactComponentInstance
  const invalidInput = sectionViewRef?.focusErrors()
  if (invalidInput) {
    errors.invalid_card = {$input: null, showError: this.showError}
  } else {
    delete errors.invalid_card
  }
  return errors
}

EditView.prototype.validateFinalGrader = function (data) {
  const errors = {}
  if (data.moderated_grading === 'on' && !data.final_grader_id) {
    errors.final_grader_id = [
      {
        message: I18n.t('Must select a grader'),
      },
    ]
    $(document).trigger('validateFinalGraderSelectedValue', {error: true})
  }
  return errors
}

EditView.prototype.validateGraderCount = function (data) {
  const errors = {}
  if (data.moderated_grading !== 'on') {
    return errors
  }
  let message
  if (!data.grader_count) {
    message = I18n.t('Must have at least one grader')
  } else if (data.grader_count > ENV.MODERATED_GRADING_GRADER_LIMIT) {
    message = I18n.t('Only a maximum of %{max} graders can be assigned', {
      max: ENV.MODERATED_GRADING_GRADER_LIMIT,
    })
  }

  if (message) {
    errors.grader_count = [{message}]
    $(document).trigger('validateGraderCountNumber', {error: true})
  }
  return errors
}

EditView.prototype.validateInput = function (e) {
  const inputValue = e.target.value
  if (inputValue) {
    const data = this.getFormData()
    let errors = {}
    switch (e.target.name) {
      case ASSIGNMENT_NAME_INPUT_NAME:
        errors = this._validateTitle(data, {})
        break
      case ALLOWED_EXTENSIONS_INPUT_NAME:
        errors = this._validateAllowedExtensions(data, {})
        break
      case POINTS_POSSIBLE_INPUT_NAME:
        errors = this._validatePointsPossible(data, {})
        break
      default:
        break
    }
    if (Object.keys(errors).length > 0) {
      this.showErrors(errors)
    } else {
      this.hideErrors(`${e.target.name}_errors`)
    }
  } else {
    this.hideErrors(`${e.target.name}_errors`)
  }
}

EditView.prototype._validateTitle = function (data, errors) {
  let max_name_length
  if (includes(this.model.frozenAttributes(), 'title')) {
    return errors
  }
  const post_to_sis = data.post_to_sis === '1'
  max_name_length = 255
  if (
    post_to_sis &&
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT &&
    data.grading_type !== 'not_graded'
  ) {
    max_name_length = ENV.MAX_NAME_LENGTH
  }
  const validationHelper = new SisValidationHelper({
    postToSIS: post_to_sis,
    maxNameLength: max_name_length,
    name: data.name,
    maxNameLengthRequired: ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT,
  })
  if (!data.name || $.trim(data.name.toString()).length === 0) {
    errors.name = [
      {
        message: I18n.t('name_is_required', 'Name is required'),
      },
    ]
  } else if (
    (post_to_sis && validationHelper.nameTooLong()) ||
    (!post_to_sis && data.name.length > max_name_length)
  ) {
    errors.name = [
      {
        message: I18n.t('Must be fewer than %{length} characters', {
          length: max_name_length + 1,
        }),
      },
    ]
  }
  return errors
}

EditView.prototype._validateSubmissionTypes = function (data, errors) {
  let allow_vericite, annotatedDocumentUsageRights, ref, ref1
  if (data.submission_type === 'online' && data.submission_types.length === 0) {
    errors[ONLINE_SUBMISSION_CHECKBOXES_GROUP] = [
      {
        message: I18n.t(
          'at_least_one_submission_type',
          'Please choose at least one submission type',
        ),
      },
    ]
  } else if (data.submission_type === 'online' && data.vericite_enabled === '1') {
    allow_vericite = true
    forEach(keys(data.submission_types), function (k) {
      allow_vericite =
        allow_vericite &&
        (data.submission_types[k] === 'online_upload' ||
          data.submission_types[k] === 'online_text_entry')
    })
    if (!allow_vericite) {
      errors[ONLINE_SUBMISSION_CHECKBOXES_GROUP] = [
        {
          message: I18n.t(
            'vericite_submission_types_validation',
            'VeriCite only supports file submissions and text entry',
          ),
        },
      ]
    }
  } else if (
    !this.getAnnotatedDocument() &&
    ((ref = data.submission_types) != null ? ref.includes('student_annotation') : void 0)
  ) {
    errors['online_submission_types[student_annotation]'] = [
      {
        message: I18n.t('This submission type requires a file upload'),
      },
    ]
  } else if (
    this.getAnnotatedDocument() &&
    ((ref1 = data.submission_types) != null ? ref1.includes('student_annotation') : void 0) &&
    this.shouldRenderUsageRights()
  ) {
    annotatedDocumentUsageRights = this.getAnnotatedDocumentUsageRights()
    if (annotatedDocumentUsageRights.use_justification === 'choose') {
      errors[USAGE_RIGHTS_SELECT] = [
        {
          message: I18n.t('Identifying the usage rights is required'),
        },
      ]
      $(document).trigger('validateUsageRightsSelectedValue', {error: true})
    }
  }
  return errors
}

EditView.prototype._validateAllowedExtensions = function (data, errors) {
  const shouldValidate = data.allowed_extensions && includes(data.submission_types, 'online_upload')
  if (shouldValidate && data.allowed_extensions.length === 0) {
    errors.allowed_extensions = [
      {
        message: I18n.t('at_least_one_file_type', 'Please specify at least one allowed file type'),
      },
    ]
  } else if (shouldValidate && YAML.stringify(data.allowed_extensions)?.length > 255) {
    errors.allowed_extensions = [
      {
        message: I18n.t('allowed_extensions_max', 'Must be fewer than 256 characters'),
      },
    ]
  }
  return errors
}

EditView.prototype._validatePointsPossible = function (data, errors) {
  if (
    includes(this.model.frozenAttributes(), 'points_possible') ||
    this.lockedItems.points ||
    data.grading_type === 'not_graded'
  ) {
    return errors
  }
  if (this.lockedItems.points) {
    return errors
  }

  if ([undefined, '', null].includes(data.points_possible) || data.points_possible < 0) {
    errors.points_possible = [
      {
        message: I18n.t('points_possible_positive', 'Points value must be 0 or greater'),
      },
    ]
  } else if (typeof data.points_possible !== 'number' || isNaN(data.points_possible)) {
    errors.points_possible = [
      {
        message: I18n.t('points_possible_number', 'Points value must be a number'),
      },
    ]
  } else if (data.points_possible > 999999999) {
    errors.points_possible = [
      {
        message: I18n.t('points_possible_max', 'Points value must be 999999999 or less'),
      },
    ]
  }
  return errors
}

EditView.prototype._validateExternalTool = function (data, errors) {
  if (data.submission_type !== 'external_tool') {
    return errors
  }

  let message
  let longMessage = false
  const toolUrl = data.external_tool_tag_attributes?.url?.toString()?.trim() || ''
  if (data.grading_type !== 'not_graded' && !toolUrl) {
    message = I18n.t('External Tool URL cannot be left blank')
  } else {
    // We are moving the url input validation to this method so we can display our own
    // errors instead of the native browser tooltip error.
    try {
      new URL(toolUrl)
      // do nothing if it is a valid url
    } catch {
      message = I18n.t('Enter a valid URL or use "Find" button to search for an external tool')
      longMessage = true
    }
  }

  if (message) {
    errors[EXTERNAL_TOOL_URL_INPUT_NAME] = [{message, longMessage}]
    errors[DEFAULT_TOOL_LAUNCH_BUTTON] = [{message, longMessage}]
  }

  // This can happen when:
  // * user chooses a tool in the submission type dropdown (Submission Type
  //   Selection placement) but doesn't launch the tool and finish deep linking
  //   flow
  // * user edits assignment and removes resource by clicking the 'x'
  //   (we reset content_type back to 'context_external_tool' then)
  if (
    typeof data.external_tool_tag_attributes === 'object' &&
    this.selectedTool?.require_resource_selection &&
    data.external_tool_tag_attributes.content_type ===
      DEFAULT_SUBMISSION_TYPE_SELECTION_CONTENT_TYPE
  ) {
    message = I18n.t('Please click above to launch the tool and select a resource.')
    errors[SUBMISSION_TYPE_SELECTION_LAUNCH_BUTTON] = [{message, longMessage: true}]
  }

  return errors
}

EditView.prototype._validateAllowedAttempts = function (data, errors) {
  if (!(typeof ENV !== 'undefined' && ENV !== null ? ENV.assignment_attempts_enabled : void 0)) {
    return errors
  }
  if (this.lockedItems.settings) {
    return errors
  }
  const value = parseInt(data.allowed_attempts, 10)

  let message
  if (isNaN(value) || !(value > 0 || value === -1)) {
    message = I18n.t('Number of attempts must be a number greater than 0')
  } else if (value > 100) {
    message = I18n.t('Number of attempts must be less than or equal to 100')
  }

  if (message) {
    errors.allowed_attempts = [{message}]
    $(document).trigger('validateAllowedAttempts', {error: true})
  }

  return errors
}

EditView.prototype.redirectAfterSave = function () {
  return (window.location = this.locationAfterSave(deparam()))
}

EditView.prototype.locationAfterSave = function (params) {
  if (returnToHelper.isValid(params.return_to) && !this.assignment.showBuildButton()) {
    return params.return_to
  }
  const useCancelLocation = this.assignment.showBuildButton() && this.preventBuildNavigation
  if (useCancelLocation) {
    return this.locationAfterCancel(deparam())
  }

  try {
    queryClient.invalidateQueries({
      queryKey: ['assignment-self-assessment-settings', this.assignment.id],
      exact: false,
    })
  } catch (error) {
    console.error('Error invalidating query, error:', error)
  }

  const htmlUrl = this.model.get('html_url')
  if (this.assignment.showBuildButton()) {
    let displayType = 'full_width'
    if (ENV.FEATURES.new_quizzes_navigation_updates) {
      displayType = 'full_width_with_nav'
    }
    return htmlUrl + `?display=${displayType}`
  } else {
    return htmlUrl
  }
}

EditView.prototype.redirectAfterCancel = function () {
  const location = this.locationAfterCancel(deparam())
  if (location) {
    return (window.location = location)
  }
}

EditView.prototype.locationAfterCancel = function (params) {
  if (returnToHelper.isValid(params.return_to)) {
    return params.return_to
  }
  if (ENV.CAN_CANCEL_TO && ENV.CAN_CANCEL_TO.includes(document.referrer)) {
    return document.referrer
  }
  if (ENV.CANCEL_TO != null) {
    return ENV.CANCEL_TO
  }
  return null
}

EditView.prototype.onChange = function () {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && this.assignmentUpToDate) {
    return (this.assignmentUpToDate = false)
  }
}

EditView.prototype.updateConditionalRelease = function () {
  let assignmentData
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !this.assignmentUpToDate) {
    assignmentData = this.getFormData()
    this.conditionalReleaseEditor.updateAssignment(assignmentData)
    return (this.assignmentUpToDate = true)
  }
}

EditView.prototype.disableFields = function () {
  const ignoreFields = [
    '#overrides-wrapper *',
    '#submission_type_fields *',
    '#assignment_peer_reviews_fields *',
    '#assignment_description',
    '#assignment_notify_of_update',
    '#assignment_post_to_sis',
  ]
  const ignoreFilter = ignoreFields
    .map(function (field) {
      return 'not(' + field + ')'
    })
    .join(':')
  const self = this
  this.$el.find(':checkbox:' + ignoreFilter).each(function () {
    return self.disableCheckbox(
      $(this),
      I18n.t('Cannot be edited for assignments in closed grading periods'),
    )
  })
  this.$el.find(':radio:' + ignoreFilter).click(this.ignoreClickHandler)
  return this.$el.find('select:' + ignoreFilter).each(this.lockSelectValueHandler)
}

EditView.prototype.ignoreClickHandler = function (event) {
  event.preventDefault()
  return event.stopPropagation()
}

EditView.prototype.lockSelectValueHandler = function () {
  const lockedValue = this.value
  return $(this).change(function (event) {
    this.value = lockedValue
    return event.stopPropagation()
  })
}

EditView.prototype.handleModeratedGradingChanged = function (isModerated) {
  this.assignment.moderatedGrading(isModerated)
  this.togglePeerReviewsAndGroupCategoryEnabled()
  if (isModerated) {
    if (this.assignment.graderCommentsVisibleToGraders()) {
      return this.$gradersAnonymousToGradersLabel.show()
    }
  } else {
    return this.uncheckAndHideGraderAnonymousToGraders()
  }
}

EditView.prototype.handleGraderCommentsVisibleToGradersChanged = function (commentsVisible) {
  this.assignment.graderCommentsVisibleToGraders(commentsVisible)
  if (commentsVisible) {
    return this.$gradersAnonymousToGradersLabel.show()
  } else {
    return this.uncheckAndHideGraderAnonymousToGraders()
  }
}

EditView.prototype.uncheckAndHideGraderAnonymousToGraders = function () {
  this.assignment.gradersAnonymousToGraders(false)
  $('#assignment_graders_anonymous_to_graders').prop('checked', false)
  return this.$gradersAnonymousToGradersLabel.hide()
}

EditView.prototype.renderModeratedGradingFormFieldGroup = function () {
  if (!ENV.MODERATED_GRADING_ENABLED || this.assignment.isQuizLTIAssignment()) {
    return
  }
  const clearNumberInputErrors = () => {
    $(document).trigger('validateGraderCountNumber', {error: false})
    this.hideErrors('grader_count_errors')
  }
  const clearFinalGraderSelectErrors = () => {
    $(document).trigger('validateFinalGraderSelectedValue', {error: false})
    this.hideErrors('final_grader_id_errors')
  }
  const props = {
    availableModerators: ENV.AVAILABLE_MODERATORS,
    currentGraderCount: this.assignment.get('grader_count'),
    finalGraderID: this.assignment.get('final_grader_id'),
    graderCommentsVisibleToGraders: this.assignment.graderCommentsVisibleToGraders(),
    graderNamesVisibleToFinalGrader: !!this.assignment.get('grader_names_visible_to_final_grader'),
    gradedSubmissionsExist: ENV.HAS_GRADED_SUBMISSIONS,
    isGroupAssignment: !!this.$groupCategoryBox.prop('checked'),
    isPeerReviewAssignment: !!this.$peerReviewsBox.prop('checked'),
    locale: ENV.LOCALE,
    moderatedGradingEnabled: this.assignment.moderatedGrading(),
    availableGradersCount: ENV.MODERATED_GRADING_MAX_GRADER_COUNT,
    onGraderCommentsVisibleToGradersChange: this.handleGraderCommentsVisibleToGradersChanged,
    onModeratedGradingChange: this.handleModeratedGradingChanged,
    hideNumberInputErrors: clearNumberInputErrors,
    hideFinalGraderErrors: clearFinalGraderSelectErrors,
  }
  const formFieldGroup = React.createElement(ModeratedGradingFormFieldGroup, props)
  const mountPoint = document.querySelector("[data-component='ModeratedGradingFormFieldGroup']")
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(formFieldGroup, mountPoint)
}

EditView.prototype.renderAllowedAttempts = function () {
  const clearErrors = () => {
    $(document).trigger('validateAllowedAttempts', {error: false})
    this.hideErrors('allowed_attempts_errors')
  }
  if (!(typeof ENV !== 'undefined' && ENV !== null ? ENV.assignment_attempts_enabled : void 0)) {
    return
  }
  const props = {
    limited: this.model.get('allowed_attempts') > 0,
    attempts: this.model.get('allowed_attempts'),
    locked: !!this.lockedItems.settings,
    onHideErrors: clearErrors,
  }
  const mountPoint = document.querySelector('#allowed-attempts-target')
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(React.createElement(AllowedAttemptsWithState, props), mountPoint)
}

export default EditView

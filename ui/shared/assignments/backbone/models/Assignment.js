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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import {map, find, filter, includes, some} from 'lodash'
import {Model} from '@canvas/backbone'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import TurnitinSettings from '../../TurnitinSettings'
import VeriCiteSettings from '../../VeriCiteSettings'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import AssignmentOverrideCollection from '../collections/AssignmentOverrideCollection'
import DateGroupCollection from '@canvas/date-group/backbone/collections/DateGroupCollection'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradingPeriodsHelper from '@canvas/grading/GradingPeriodsHelper'
import * as tz from '@canvas/datetime'
import numberHelper from '@canvas/i18n/numberHelper'
import PandaPubPoller from '@canvas/panda-pub-poller'
import {matchingToolUrls} from './LtiAssignmentHelpers'

const default_interval = 3000
const I18n = useI18nScope('models_Assignment')

const hasProp = {}.hasOwnProperty

const LTI_EXT_MASTERY_CONNECT = 'https://canvas.instructure.com/lti/mastery_connect_assessment'

const canManage = function () {
  let ref
  return (ref = ENV.PERMISSIONS) != null ? ref.manage : void 0
}

const isAdmin = function () {
  return ENV.current_user_is_admin
}

// must check canManage because current_user_roles will include roles from other enrolled courses
const isStudent = function () {
  return (ENV.current_user_roles || []).includes('student') && !canManage()
}

extend(Assignment, Model)

function Assignment() {
  this.abGuid = this.abGuid.bind(this)
  this.quizzesRespondusEnabled = this.quizzesRespondusEnabled.bind(this)
  this.showGradersAnonymousToGradersCheckbox = this.showGradersAnonymousToGradersCheckbox.bind(this)
  this.pollUntilFinished = this.pollUntilFinished.bind(this)
  this.pollUntilFinishedLoading = this.pollUntilFinishedLoading.bind(this)
  this.pollUntilFinishedMigrating = this.pollUntilFinishedMigrating.bind(this)
  this.pollUntilFinishedImporting = this.pollUntilFinishedImporting.bind(this)
  this.pollUntilFinishedDuplicating = this.pollUntilFinishedDuplicating.bind(this)
  this.retry_migration = this.retry_migration.bind(this)
  this.duplicate_failed = this.duplicate_failed.bind(this)
  this.duplicate = this.duplicate.bind(this)
  this.setNullDates = this.setNullDates.bind(this)
  this._filterFrozenAttributes = this._filterFrozenAttributes.bind(this)
  this._getAssignmentType = this._getAssignmentType.bind(this)
  this._hasOnlyType = this._hasOnlyType.bind(this)
  this._submissionTypes = this._submissionTypes.bind(this)
  this.toView = this.toView.bind(this)
  this.submissionTypesFrozen = this.submissionTypesFrozen.bind(this)
  this.failedToImport = this.failedToImport.bind(this)
  this.isImporting = this.isImporting.bind(this)
  this.isQuizLTIAssignment = this.isQuizLTIAssignment.bind(this)
  this.is_quiz_assignment = this.is_quiz_assignment.bind(this)
  this.originalAssignmentName = this.originalAssignmentName.bind(this)
  this.originalAssignmentID = this.originalAssignmentID.bind(this)
  this.originalQuizID = this.originalQuizID.bind(this)
  this.originalCourseID = this.originalCourseID.bind(this)
  this.failedToMigrate = this.failedToMigrate.bind(this)
  this.failedToDuplicate = this.failedToDuplicate.bind(this)
  this.isMigrating = this.isMigrating.bind(this)
  this.isMasterCourseChildContent = this.isMasterCourseChildContent.bind(this)
  this.isDuplicating = this.isDuplicating.bind(this)
  this.canDuplicate = this.canDuplicate.bind(this)
  this.singleSectionDueDate = this.singleSectionDueDate.bind(this)
  this.singleSection = this.singleSection.bind(this)
  this.allDates = this.allDates.bind(this)
  this.nonBaseDates = this.nonBaseDates.bind(this)
  this.hasPointsPossible = this.hasPointsPossible.bind(this)
  this.hasDueDate = this.hasDueDate.bind(this)
  this.multipleDueDates = this.multipleDueDates.bind(this)
  this.defaultDates = this.defaultDates.bind(this)
  this.showBuildButton = this.showBuildButton.bind(this)
  this.newQuizzesAssignmentBuildButtonEnabled =
    this.newQuizzesAssignmentBuildButtonEnabled.bind(this)
  this.hideZeroPointQuizzesOptionEnabled = this.hideZeroPointQuizzesOptionEnabled.bind(this)
  this.submissionTypeSelectionTools = this.submissionTypeSelectionTools.bind(this)
  this.dueDateRequiredForAccount = this.dueDateRequiredForAccount.bind(this)
  this.maxNameLengthRequiredForAccount = this.maxNameLengthRequiredForAccount.bind(this)
  this.maxNameLength = this.maxNameLength.bind(this)
  this.sisIntegrationSettingsEnabled = this.sisIntegrationSettingsEnabled.bind(this)
  this.postToSISName = this.postToSISName.bind(this)
  this.postToSISEnabled = this.postToSISEnabled.bind(this)
  this.labelId = this.labelId.bind(this)
  this.htmlBuildUrl = this.htmlBuildUrl.bind(this)
  this.htmlEditUrl = this.htmlEditUrl.bind(this)
  this.htmlUrl = this.htmlUrl.bind(this)
  this.objectType = this.objectType.bind(this)
  this.iconType = this.iconType.bind(this)
  this.useNewQuizIcon = this.useNewQuizIcon.bind(this)
  this.published = this.published.bind(this)
  this.isGpaScaled = this.isGpaScaled.bind(this)
  this.isLetterGraded = this.isLetterGraded.bind(this)
  this.isSimple = this.isSimple.bind(this)
  this.externalToolNewTab = this.externalToolNewTab.bind(this)
  this.externalToolDataStudentLabelText = this.externalToolDataStudentLabelText.bind(this)
  this.isMasteryConnectTool = this.isMasteryConnectTool.bind(this)
  this.externalToolCustomParamsStringified = this.externalToolCustomParamsStringified.bind(this)
  this.externalToolCustomParams = this.externalToolCustomParams.bind(this)
  this.externalToolDataStringified = this.externalToolDataStringified.bind(this)
  this.externalToolData = this.externalToolData.bind(this)
  this.externalToolIframeHeight = this.externalToolIframeHeight.bind(this)
  this.externalToolIframeWidth = this.externalToolIframeWidth.bind(this)
  this.externalToolUrl = this.externalToolUrl.bind(this)
  this.gradingStandardId = this.gradingStandardId.bind(this)
  this.groupCategoryId = this.groupCategoryId.bind(this)
  this.vericiteEnabled = this.vericiteEnabled.bind(this)
  this.turnitinEnabled = this.turnitinEnabled.bind(this)
  this.gradeGroupStudentsIndividually = this.gradeGroupStudentsIndividually.bind(this)
  this.vericiteAvailable = this.vericiteAvailable.bind(this)
  this.turnitinAvailable = this.turnitinAvailable.bind(this)
  this.allowedExtensions = this.allowedExtensions.bind(this)
  this.restrictFileExtensions = this.restrictFileExtensions.bind(this)
  this.notifyOfUpdate = this.notifyOfUpdate.bind(this)
  this.peerReviewsAssignAt = this.peerReviewsAssignAt.bind(this)
  this.peerReviewCount = this.peerReviewCount.bind(this)
  this.automaticPeerReviews = this.automaticPeerReviews.bind(this)
  this.anonymousPeerReviews = this.anonymousPeerReviews.bind(this)
  this.peerReviews = this.peerReviews.bind(this)
  this.graderCommentsVisibleToGraders = this.graderCommentsVisibleToGraders.bind(this)
  this.gradersAnonymousToGraders = this.gradersAnonymousToGraders.bind(this)
  this.anonymousGrading = this.anonymousGrading.bind(this)
  this.anonymousInstructorAnnotations = this.anonymousInstructorAnnotations.bind(this)
  this.moderatedGrading = this.moderatedGrading.bind(this)
  this.postToSIS = this.postToSIS.bind(this)
  this.isOnlineSubmission = this.isOnlineSubmission.bind(this)
  this.acceptsOnlineTextEntries = this.acceptsOnlineTextEntries.bind(this)
  this.acceptsMediaRecording = this.acceptsMediaRecording.bind(this)
  this.acceptsOnlineURL = this.acceptsOnlineURL.bind(this)
  this.acceptsAnnotatedDocument = this.acceptsAnnotatedDocument.bind(this)
  this.acceptsOnlineUpload = this.acceptsOnlineUpload.bind(this)
  this.withoutGradedSubmission = this.withoutGradedSubmission.bind(this)
  this.hasSubmittedSubmissions = this.hasSubmittedSubmissions.bind(this)
  this.allowedToSubmit = this.allowedToSubmit.bind(this)
  this.expectsSubmission = this.expectsSubmission.bind(this)
  this.submissionType = this.submissionType.bind(this)
  this.selectedSubmissionTypeToolId = this.selectedSubmissionTypeToolId.bind(this)
  this.isNonPlacementExternalTool = this.isNonPlacementExternalTool.bind(this)
  this.isGenericExternalTool = this.isGenericExternalTool.bind(this)
  this.defaultToolSelected = this.defaultToolSelected.bind(this)
  this.isQuickCreateDefaultTool = this.isQuickCreateDefaultTool.bind(this)
  this.defaultToOnPaper = this.defaultToOnPaper.bind(this)
  this.defaultToOnline = this.defaultToOnline.bind(this)
  this.defaultToNone = this.defaultToNone.bind(this)
  this.isDefaultTool = this.isDefaultTool.bind(this)
  this.shouldShowDefaultTool = this.shouldShowDefaultTool.bind(this)
  this.isUpdateAssignmentSubmissionTypeLaunchButtonEnabled =
    this.isUpdateAssignmentSubmissionTypeLaunchButtonEnabled.bind(this)
  this.isNewAssignment = this.isNewAssignment.bind(this)
  this.submissionTypes = this.submissionTypes.bind(this)
  this.inPacedCourse = this.inPacedCourse.bind(this)
  this.courseID = this.courseID.bind(this)
  this.omitFromFinalGrade = this.omitFromFinalGrade.bind(this)
  this.hideInGradebook = this.hideInGradebook.bind(this)
  this.gradingType = this.gradingType.bind(this)
  this.gradedSubmissionsExist = this.gradedSubmissionsExist.bind(this)
  this.inClosedGradingPeriod = this.inClosedGradingPeriod.bind(this)
  this.frozenAttributes = this.frozenAttributes.bind(this)
  this.frozen = this.frozen.bind(this)
  this.freezeOnCopy = this.freezeOnCopy.bind(this)
  this.canMove = this.canMove.bind(this)
  this.canDelete = this.canDelete.bind(this)
  this.canFreeze = this.canFreeze.bind(this)
  this.assignmentGroupId = this.assignmentGroupId.bind(this)
  this.secureParams = this.secureParams.bind(this)
  this.pointsPossible = this.pointsPossible.bind(this)
  this.name = this.name.bind(this)
  this.description = this.description.bind(this)
  this.importantDates = this.importantDates.bind(this)
  this.dueDateRequired = this.dueDateRequired.bind(this)
  this.lockAt = this.lockAt.bind(this)
  this.unlockAt = this.unlockAt.bind(this)
  this.dueAt = this.dueAt.bind(this)
  this.assignmentType = this.assignmentType.bind(this)
  this.isNotGraded = this.isNotGraded.bind(this)
  this.defaultToolUrl = this.defaultToolUrl.bind(this)
  this.defaultToolName = this.defaultToolName.bind(this)
  this.isNonPlacementExternalTool = this.isNonPlacementExternalTool.bind(this)
  this.isExternalTool = this.isExternalTool.bind(this)
  this.isPage = this.isPage.bind(this)
  this.isDiscussionTopic = this.isDiscussionTopic.bind(this)
  this.isQuiz = this.isQuiz.bind(this)
  this.isCloningAlignment = this.isCloningAlignment.bind(this)
  this.pollUntilFinishedCloningAlignment = this.pollUntilFinishedCloningAlignment.bind(this)
  this.failedToCloneAlignment = this.failedToCloneAlignment.bind(this)
  this.alignment_clone_failed = this.alignment_clone_failed.bind(this)
  return Assignment.__super__.constructor.apply(this, arguments)
}

Assignment.mixin(DefaultUrlMixin)

Assignment.prototype.resourceName = 'assignments'

Assignment.prototype.urlRoot = function () {
  return this._defaultUrl()
}

Assignment.prototype.defaults = {
  publishable: true,
  hidden: false,
  unpublishable: true,
}

Assignment.prototype.initialize = function () {
  let all_dates, overrides, turnitin_settings, vericite_settings
  if ((overrides = this.get('assignment_overrides')) != null) {
    this.set('assignment_overrides', new AssignmentOverrideCollection(overrides))
  }
  if ((turnitin_settings = this.get('turnitin_settings')) != null) {
    this.set('turnitin_settings', new TurnitinSettings(turnitin_settings), {
      silent: true,
    })
  }
  if ((vericite_settings = this.get('vericite_settings')) != null) {
    this.set('vericite_settings', new VeriCiteSettings(vericite_settings), {
      silent: true,
    })
  }
  if ((all_dates = this.get('all_dates')) != null) {
    this.set('all_dates', new DateGroupCollection(all_dates))
  }
  if (this.postToSISEnabled()) {
    if (!this.get('id') && this.get('post_to_sis') !== false) {
      return this.set(
        'post_to_sis',
        !!(typeof ENV !== 'undefined' && ENV !== null ? ENV.POST_TO_SIS_DEFAULT : void 0)
      )
    }
  }
}

Assignment.prototype.isQuiz = function () {
  return this._hasOnlyType('online_quiz')
}

Assignment.prototype.isDiscussionTopic = function () {
  return this._hasOnlyType('discussion_topic')
}

Assignment.prototype.isPage = function () {
  return this._hasOnlyType('wiki_page')
}

Assignment.prototype.isExternalTool = function () {
  return this._hasOnlyType('external_tool')
}

Assignment.prototype.isNonPlacementExternalTool = function () {
  return this.isExternalTool
}

Assignment.prototype.defaultToolName = function () {
  return (
    ENV.DEFAULT_ASSIGNMENT_TOOL_NAME &&
    escape(ENV.DEFAULT_ASSIGNMENT_TOOL_NAME).replace(/%20/g, ' ')
  )
}

Assignment.prototype.defaultToolUrl = function () {
  return ENV.DEFAULT_ASSIGNMENT_TOOL_URL
}

Assignment.prototype.isNotGraded = function () {
  return this._hasOnlyType('not_graded')
}

Assignment.prototype.assignmentType = function (type) {
  if (!(arguments.length > 0)) {
    return this._getAssignmentType()
  }
  if (type === 'assignment') {
    return this.set('submission_types', ['none'])
  } else {
    return this.set('submission_types', [type])
  }
}

Assignment.prototype.abGuid = function (ab_guid) {
  if (!(arguments.length > 0)) {
    return this.get('ab_guid')
  }
  return this.set('ab_guid', ab_guid)
}

Assignment.prototype.dueAt = function (date) {
  if (!(arguments.length > 0)) {
    return this.get('due_at')
  }
  return this.set('due_at', date)
}

Assignment.prototype.unlockAt = function (date) {
  if (!(arguments.length > 0)) {
    return this.get('unlock_at')
  }
  return this.set('unlock_at', date)
}

Assignment.prototype.lockAt = function (date) {
  if (!(arguments.length > 0)) {
    return this.get('lock_at')
  }
  return this.set('lock_at', date)
}

Assignment.prototype.dueDateRequired = function (newDueDateRequired) {
  if (!(arguments.length > 0)) {
    return this.get('dueDateRequired')
  }
  return this.set('dueDateRequired', newDueDateRequired)
}

Assignment.prototype.importantDates = function (important) {
  if (!(arguments.length > 0)) {
    return this.get('important_dates')
  }
  return this.set('important_dates', important)
}

Assignment.prototype.description = function (newDescription) {
  if (!(arguments.length > 0)) {
    return this.get('description')
  }
  return this.set('description', newDescription)
}

Assignment.prototype.name = function (newName) {
  if (!(arguments.length > 0)) {
    return this.get('name')
  }
  return this.set('name', newName)
}

Assignment.prototype.pointsPossible = function (points) {
  if (!(arguments.length > 0)) {
    return this.get('points_possible') || 0
  }
  // if the incoming value is valid, set the field to the numeric value
  // if not, set to the incoming string and let validation handle it later
  if (numberHelper.validate(points)) {
    return this.set('points_possible', numberHelper.parse(points))
  } else {
    return this.set('points_possible', points)
  }
}

Assignment.prototype.secureParams = function () {
  return this.get('secure_params')
}

Assignment.prototype.assignmentGroupId = function (assignment_group_id) {
  if (!(arguments.length > 0)) {
    return this.get('assignment_group_id')
  }
  return this.set('assignment_group_id', assignment_group_id)
}

Assignment.prototype.canFreeze = function () {
  return this.get('frozen_attributes') != null && !this.frozen() && !this.isQuizLTIAssignment()
}

Assignment.prototype.canDelete = function () {
  return !this.inClosedGradingPeriod() && !this.frozen()
}

Assignment.prototype.canMove = function () {
  return !this.inClosedGradingPeriod() && !includes(this.frozenAttributes(), 'assignment_group_id')
}

Assignment.prototype.freezeOnCopy = function () {
  return this.get('freeze_on_copy')
}

Assignment.prototype.frozen = function () {
  return this.get('frozen')
}

Assignment.prototype.frozenAttributes = function () {
  return this.get('frozen_attributes') || []
}

Assignment.prototype.inClosedGradingPeriod = function () {
  if (isAdmin()) {
    return false
  }
  return this.get('in_closed_grading_period')
}

Assignment.prototype.gradedSubmissionsExist = function () {
  return this.get('graded_submissions_exist')
}

Assignment.prototype.gradingType = function (gradingType) {
  if (!gradingType) {
    return this.get('grading_type') || 'points'
  }
  return this.set('grading_type', gradingType)
}

Assignment.prototype.omitFromFinalGrade = function (omitFromFinalGradeBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('omit_from_final_grade')
  }
  return this.set('omit_from_final_grade', omitFromFinalGradeBoolean)
}

Assignment.prototype.hideInGradebook = function (hideInGradebookBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('hide_in_gradebook')
  }
  return this.set('hide_in_gradebook', hideInGradebookBoolean)
}

Assignment.prototype.courseID = function () {
  return this.get('course_id')
}

Assignment.prototype.inPacedCourse = function () {
  return this.get('in_paced_course')
}

Assignment.prototype.submissionTypes = function (submissionTypes) {
  if (!(arguments.length > 0)) {
    return this._submissionTypes()
  }
  return this.set('submission_types', submissionTypes)
}

Assignment.prototype.isNewAssignment = function () {
  return !this.name()
}

Assignment.prototype.shouldShowDefaultTool = function () {
  if (!this.defaultToolUrl()) {
    return false
  }
  return this.defaultToolSelected() || this.isQuickCreateDefaultTool() || this.isNewAssignment()
}

Assignment.prototype.isDefaultTool = function () {
  return this.submissionType() === 'external_tool' && this.shouldShowDefaultTool()
}

Assignment.prototype.isUpdateAssignmentSubmissionTypeLaunchButtonEnabled = function () {
  return window.ENV.UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED
}

Assignment.prototype.defaultToNone = function () {
  return this.submissionType() === 'none' && !this.shouldShowDefaultTool()
}

Assignment.prototype.defaultToOnline = function () {
  return this.submissionType() === 'online' && !this.shouldShowDefaultTool()
}

Assignment.prototype.defaultToOnPaper = function () {
  return this.submissionType() === 'on_paper' && !this.shouldShowDefaultTool()
}

Assignment.prototype.isQuickCreateDefaultTool = function () {
  return this.submissionTypes().includes('default_external_tool')
}

Assignment.prototype.defaultToolSelected = function () {
  return matchingToolUrls(this.defaultToolUrl(), this.externalToolUrl())
}

Assignment.prototype.isGenericExternalTool = function () {
  // The assignment is type 'external_tool' and the default tool is not selected
  // or chosen from the "quick create" assignment index modal
  // or via the submission_type_selection placement type
  return (
    this.submissionType() === 'external_tool' &&
    !this.isDefaultTool() &&
    !this.selectedSubmissionTypeToolId()
  )
}

Assignment.prototype.isNonPlacementExternalTool = function () {
  // The assignment is type 'external_tool' and the tool is not selected
  // via the submission_type_selection placement type
  return this.submissionType() === 'external_tool' && !this.selectedSubmissionTypeToolId()
}

Assignment.prototype.selectedSubmissionTypeToolId = function () {
  let ref
  if (this.submissionType() !== 'external_tool') {
    return
  }
  const tool_id = (ref = this.get('external_tool_tag_attributes')) != null ? ref.content_id : void 0
  if (
    tool_id &&
    find(this.submissionTypeSelectionTools(), function (tool) {
      return tool_id === tool.id
    })
  ) {
    return tool_id
  }
}

Assignment.prototype.submissionType = function () {
  const submissionTypes = this._submissionTypes() || []
  if (submissionTypes.length === 0 || submissionTypes.includes('none')) {
    return 'none'
  } else if (submissionTypes.includes('on_paper')) {
    return 'on_paper'
  } else if (submissionTypes.includes('external_tool')) {
    return 'external_tool'
  } else if (submissionTypes.includes('default_external_tool')) {
    return 'external_tool'
  } else {
    return 'online'
  }
}

Assignment.prototype.expectsSubmission = function () {
  const submissionTypes = this._submissionTypes() || []
  return (
    submissionTypes.length > 0 &&
    !submissionTypes.includes('') &&
    !submissionTypes.includes('none') &&
    !submissionTypes.includes('not_graded') &&
    !submissionTypes.includes('on_paper') &&
    !submissionTypes.includes('external_tool')
  )
}

Assignment.prototype.allowedToSubmit = function () {
  const submissionTypes = this._submissionTypes() || []
  return (
    this.expectsSubmission() &&
    !this.get('locked_for_user') &&
    !submissionTypes.includes('online_quiz') &&
    !submissionTypes.includes('attendance')
  )
}

Assignment.prototype.hasSubmittedSubmissions = function () {
  return this.get('has_submitted_submissions')
}

Assignment.prototype.withoutGradedSubmission = function () {
  const sub = this.get('submission')
  return sub == null || sub.withoutGradedSubmission()
}

Assignment.prototype.acceptsOnlineUpload = function () {
  const submissionTypes = this._submissionTypes() || []
  return submissionTypes.includes('online_upload')
}

Assignment.prototype.acceptsAnnotatedDocument = function () {
  const submissionTypes = this._submissionTypes() || []
  return submissionTypes.includes('student_annotation')
}

Assignment.prototype.acceptsOnlineURL = function () {
  const submissionTypes = this._submissionTypes() || []
  return submissionTypes.includes('online_url')
}

Assignment.prototype.acceptsMediaRecording = function () {
  const submissionTypes = this._submissionTypes() || []
  return submissionTypes.includes('media_recording')
}

Assignment.prototype.acceptsOnlineTextEntries = function () {
  const submissionTypes = this._submissionTypes() || []
  return submissionTypes.includes('online_text_entry')
}

Assignment.prototype.isOnlineSubmission = function () {
  return (this._submissionTypes() || []).some(function (thing) {
    return (
      thing === 'online' ||
      thing === 'online_text_entry' ||
      thing === 'media_recording' ||
      thing === 'online_url' ||
      thing === 'online_upload' ||
      thing === 'student_annotation'
    )
  })
}

Assignment.prototype.postToSIS = function (postToSisBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('post_to_sis')
  }
  return this.set('post_to_sis', postToSisBoolean)
}

Assignment.prototype.moderatedGrading = function (enabled) {
  if (!(arguments.length > 0)) {
    return this.get('moderated_grading') || false
  }
  return this.set('moderated_grading', enabled)
}

Assignment.prototype.anonymousInstructorAnnotations = function (
  anonymousInstructorAnnotationsBoolean
) {
  if (!(arguments.length > 0)) {
    return this.get('anonymous_instructor_annotations')
  }
  return this.set('anonymous_instructor_annotations', anonymousInstructorAnnotationsBoolean)
}

Assignment.prototype.anonymousGrading = function (anonymousGradingBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('anonymous_grading')
  }
  return this.set('anonymous_grading', anonymousGradingBoolean)
}

Assignment.prototype.gradersAnonymousToGraders = function (anonymousGraders) {
  if (!(arguments.length > 0)) {
    return this.get('graders_anonymous_to_graders')
  }
  return this.set('graders_anonymous_to_graders', anonymousGraders)
}

Assignment.prototype.graderCommentsVisibleToGraders = function (commentsVisible) {
  if (!(arguments.length > 0)) {
    return !!this.get('grader_comments_visible_to_graders')
  }
  return this.set('grader_comments_visible_to_graders', commentsVisible)
}

Assignment.prototype.peerReviews = function (peerReviewBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('peer_reviews')
  }
  return this.set('peer_reviews', peerReviewBoolean)
}

Assignment.prototype.anonymousPeerReviews = function (anonymousPeerReviewBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('anonymous_peer_reviews')
  }
  return this.set('anonymous_peer_reviews', anonymousPeerReviewBoolean)
}

Assignment.prototype.automaticPeerReviews = function (autoPeerReviewBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('automatic_peer_reviews')
  }
  return this.set('automatic_peer_reviews', autoPeerReviewBoolean)
}

Assignment.prototype.peerReviewCount = function (peerReviewCount) {
  if (!(arguments.length > 0)) {
    return this.get('peer_review_count') || 0
  }
  return this.set('peer_review_count', peerReviewCount)
}

Assignment.prototype.peerReviewsAssignAt = function (date) {
  if (!(arguments.length > 0)) {
    return this.get('peer_reviews_assign_at') || null
  }
  return this.set('peer_reviews_assign_at', date)
}

Assignment.prototype.intraGroupPeerReviews = function () {
  return this.get('intra_group_peer_reviews')
}

Assignment.prototype.notifyOfUpdate = function (notifyOfUpdateBoolean) {
  if (!(arguments.length > 0)) {
    return this.get('notify_of_update')
  }
  return this.set('notify_of_update', notifyOfUpdateBoolean)
}

Assignment.prototype.restrictFileExtensions = function () {
  return !!this.allowedExtensions()
}

Assignment.prototype.allowedExtensions = function (extensionsList) {
  if (!(arguments.length > 0)) {
    return this.get('allowed_extensions')
  }
  return this.set('allowed_extensions', extensionsList)
}

Assignment.prototype.turnitinAvailable = function () {
  return typeof this.get('turnitin_enabled') !== 'undefined'
}

Assignment.prototype.vericiteAvailable = function () {
  return typeof this.get('vericite_enabled') !== 'undefined'
}

Assignment.prototype.gradeGroupStudentsIndividually = function (setting) {
  if (!(arguments.length > 0)) {
    return this.get('grade_group_students_individually')
  }
  return this.set('grade_group_students_individually', setting)
}

Assignment.prototype.turnitinEnabled = function (setting) {
  if (arguments.length === 0) {
    if (this.get('turnitin_enabled') === void 0) {
      return false
    } else {
      return !!this.get('turnitin_enabled')
    }
  } else {
    return this.set('turnitin_enabled', setting)
  }
}

Assignment.prototype.vericiteEnabled = function (setting) {
  if (arguments.length === 0) {
    if (this.get('vericite_enabled') === void 0) {
      return false
    } else {
      return !!this.get('vericite_enabled')
    }
  } else {
    return this.set('vericite_enabled', setting)
  }
}

Assignment.prototype.groupCategoryId = function (id) {
  if (!(arguments.length > 0)) {
    return this.get('group_category_id')
  }
  return this.set('group_category_id', id)
}

Assignment.prototype.canGroup = function () {
  return !this.get('has_submitted_submissions')
}

Assignment.prototype.isPlagiarismPlatformLocked = function () {
  return (
    this.get('has_submitted_submissions') || includes(this.frozenAttributes(), 'submission_types')
  )
}

Assignment.prototype.gradingStandardId = function (id) {
  if (!(arguments.length > 0)) {
    return this.get('grading_standard_id')
  }
  return this.set('grading_standard_id', id)
}

Assignment.prototype.externalToolUrl = function (url) {
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes.url
  }
  tagAttributes.url = url
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.externalToolIframeWidth = function (width) {
  let ref
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes != null
      ? (ref = tagAttributes.iframe) != null
        ? ref.width
        : void 0
      : void 0
  }
  tagAttributes.iframe.width = width
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.externalToolIframeHeight = function (height) {
  let ref
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes != null
      ? (ref = tagAttributes.iframe) != null
        ? ref.height
        : void 0
      : void 0
  }
  tagAttributes.iframe.height = height
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.externalToolData = function () {
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  return tagAttributes.external_data
}

Assignment.prototype.externalToolDataStringified = function () {
  const data = this.externalToolData()
  if (data) {
    return JSON.stringify(data)
  }
  return ''
}

Assignment.prototype.externalToolCustomParams = function (custom_params) {
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes.custom_params
  }
  tagAttributes.custom_params = custom_params
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.externalToolCustomParamsStringified = function () {
  const data = this.externalToolCustomParams()
  if (data) {
    return JSON.stringify(data)
  }
  return ''
}

Assignment.prototype.externalToolLineItem = function (line_item) {
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes.line_item
  }
  tagAttributes.line_item = line_item
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.externalToolLineItemStringified = function () {
  const data = this.externalToolLineItem()
  if (data) {
    return JSON.stringify(data)
  }
  return ''
}

Assignment.prototype.isMasteryConnectTool = function () {
  let ref
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  return (
    (tagAttributes != null
      ? (ref = tagAttributes.external_data) != null
        ? ref.key
        : void 0
      : void 0) === LTI_EXT_MASTERY_CONNECT
  )
}

Assignment.prototype.externalToolDataStudentLabelText = function () {
  const data = this.externalToolData()
  if (!data) {
    return ''
  }
  if (data.studentCount === 1) {
    return I18n.t('Student')
  }
  return I18n.t('Students')
}

Assignment.prototype.externalToolNewTab = function (b) {
  const tagAttributes = this.get('external_tool_tag_attributes') || {}
  if (!(arguments.length > 0)) {
    return tagAttributes.new_tab
  }
  tagAttributes.new_tab = b
  return this.set('external_tool_tag_attributes', tagAttributes)
}

Assignment.prototype.isSimple = function () {
  const overrides = this.get('assignment_overrides')
  return (
    this.gradingType() === 'points' &&
    this.submissionType() === 'none' &&
    !this.groupCategoryId() &&
    !this.peerReviews() &&
    !this.frozen() &&
    (!overrides || overrides.isSimple())
  )
}

Assignment.prototype.isLetterGraded = function () {
  return this.gradingType() === 'letter_grade'
}

Assignment.prototype.isGpaScaled = function () {
  return this.gradingType() === 'gpa_scale'
}

Assignment.prototype.published = function (newPublished) {
  if (!(arguments.length > 0)) {
    return this.get('published')
  }
  return this.set('published', newPublished)
}

Assignment.prototype.useNewQuizIcon = function () {
  return (
    ENV.FLAGS &&
    ENV.FLAGS.newquizzes_on_quiz_page &&
    ((this.isQuiz() && isStudent()) || this.isQuizLTIAssignment())
  )
}

Assignment.prototype.position = function (newPosition) {
  if (!(arguments.length > 0)) {
    return this.get('position') || 0
  }
  return this.set('position', newPosition)
}

Assignment.prototype.iconType = function () {
  if (this.useNewQuizIcon()) {
    return 'quiz icon-Solid'
  }
  if (this.isQuiz()) {
    return 'quiz'
  }
  if (this.isDiscussionTopic()) {
    return 'discussion'
  }
  if (this.isPage()) {
    return 'document'
  }
  return 'assignment'
}

Assignment.prototype.objectType = function () {
  if (this.isQuiz()) {
    return 'Quiz'
  }
  if (this.isDiscussionTopic()) {
    return 'Discussion'
  }
  if (this.isPage()) {
    return 'WikiPage'
  }
  return 'Assignment'
}

Assignment.prototype.objectTypeDisplayName = function () {
  if (this.isQuiz() || (this.isQuizLTIAssignment() && isStudent())) {
    return I18n.t('Quiz')
  }
  if (this.isQuizLTIAssignment()) {
    return I18n.t('New Quiz')
  }
  if (this.isDiscussionTopic()) {
    return I18n.t('Discussion Topic')
  }
  if (this.isPage()) {
    return I18n.t('Page')
  }
  return I18n.t('Assignment')
}

Assignment.prototype.htmlUrl = function () {
  if (this.isQuizLTIAssignment() && canManage()) {
    return this.htmlEditUrl() + '?quiz_lti'
  } else {
    return this.get('html_url')
  }
}

Assignment.prototype.htmlEditUrl = function () {
  return this.get('html_url') + '/edit'
}

Assignment.prototype.htmlBuildUrl = function () {
  return this.get('html_url')
}

Assignment.prototype.labelId = function () {
  return this.id
}

Assignment.prototype.postToSISEnabled = function () {
  return ENV.POST_TO_SIS
}

Assignment.prototype.postToSISName = function () {
  return ENV.SIS_NAME
}

Assignment.prototype.sisIntegrationSettingsEnabled = function () {
  return ENV.SIS_INTEGRATION_SETTINGS_ENABLED
}

Assignment.prototype.maxNameLength = function () {
  return ENV.MAX_NAME_LENGTH
}

Assignment.prototype.maxNameLengthRequiredForAccount = function () {
  return ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT
}

Assignment.prototype.dueDateRequiredForAccount = function () {
  return ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT
}

Assignment.prototype.submissionTypeSelectionTools = function () {
  return ENV.SUBMISSION_TYPE_SELECTION_TOOLS || []
}

Assignment.prototype.newQuizzesAssignmentBuildButtonEnabled = function () {
  return ENV.NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED
}

Assignment.prototype.hideZeroPointQuizzesOptionEnabled = function () {
  return ENV.HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED
}

Assignment.prototype.showBuildButton = function () {
  return this.isQuizLTIAssignment() && this.newQuizzesAssignmentBuildButtonEnabled()
}

Assignment.prototype.defaultDates = function () {
  const singleSection = this.singleSection()
  return new DateGroup({
    due_at: this.get('due_at'),
    unlock_at: this.get('unlock_at'),
    lock_at: this.get('lock_at'),
    single_section_unlock_at: singleSection != null ? singleSection.unlockAt : void 0,
    single_section_lock_at: singleSection != null ? singleSection.lockAt : void 0,
  })
}

Assignment.prototype.multipleDueDates = function () {
  let dateGroups
  const count = this.get('all_dates_count')
  if (count && count > 1) {
    return true
  } else {
    dateGroups = this.get('all_dates')
    return dateGroups && dateGroups.length > 1
  }
}

Assignment.prototype.hasDueDate = function () {
  return !this.isPage()
}

Assignment.prototype.hasPointsPossible = function () {
  return !this.isQuiz() && !this.isPage()
}

Assignment.prototype.nonBaseDates = function () {
  const dateGroups = this.get('all_dates')
  if (!dateGroups) {
    return false
  }
  const withouBase = filter(dateGroups.models, function (dateGroup) {
    return dateGroup && !dateGroup.get('base')
  })
  return withouBase.length > 0
}

Assignment.prototype.allDates = function () {
  const groups = this.get('all_dates')
  const models = (groups && groups.models) || []
  return map(models, function (group) {
    return group.toJSON()
  })
}

Assignment.prototype.singleSection = function () {
  let i, len, section
  const allDates = this.allDates()
  if (allDates && allDates.length === 1) {
    for (i = 0, len = allDates.length; i < len; i++) {
      section = allDates[i]
      return section
    }
  } else {
    return null
  }
}

Assignment.prototype.singleSectionDueDate = function () {
  let allDates, i, len, section
  if (!this.multipleDueDates() && !this.dueAt()) {
    allDates = this.allDates()
    for (i = 0, len = allDates.length; i < len; i++) {
      section = allDates[i]
      if (section.dueAt) {
        return section.dueAt.toISOString()
      }
    }
  } else {
    return this.dueAt()
  }
}

Assignment.prototype.canDuplicate = function () {
  return this.get('can_duplicate')
}

Assignment.prototype.isDuplicating = function () {
  return this.get('workflow_state') === 'duplicating'
}

Assignment.prototype.isCloningAlignment = function () {
  return this.get('workflow_state') === 'outcome_alignment_cloning'
}

Assignment.prototype.isMigrating = function () {
  return this.get('workflow_state') === 'migrating'
}

Assignment.prototype.isMasterCourseChildContent = function () {
  return !!this.get('is_master_course_child_content')
}

Assignment.prototype.failedToDuplicate = function () {
  return this.get('workflow_state') === 'failed_to_duplicate'
}

Assignment.prototype.failedToCloneAlignment = function () {
  return this.get('workflow_state') === 'failed_to_clone_outcome_alignment'
}

Assignment.prototype.failedToMigrate = function () {
  return this.get('workflow_state') === 'failed_to_migrate'
}

Assignment.prototype.originalCourseID = function () {
  return this.get('original_course_id')
}

Assignment.prototype.originalQuizID = function () {
  return this.get('original_quiz_id')
}

Assignment.prototype.originalAssignmentID = function () {
  return this.get('original_assignment_id')
}

Assignment.prototype.originalAssignmentName = function () {
  return this.get('original_assignment_name')
}

Assignment.prototype.is_quiz_assignment = function () {
  return this.get('is_quiz_assignment')
}

Assignment.prototype.isQuizLTIAssignment = function () {
  return this.get('is_quiz_lti_assignment')
}

Assignment.prototype.isImporting = function () {
  return this.get('workflow_state') === 'importing'
}

Assignment.prototype.failedToImport = function () {
  return this.get('workflow_state') === 'failed_to_import'
}

Assignment.prototype.submissionTypesFrozen = function () {
  return includes(this.frozenAttributes(), 'submission_types')
}

Assignment.prototype.toView = function () {
  const fields = [
    'abGuid',
    'acceptsAnnotatedDocument',
    'acceptsMediaRecording',
    'acceptsOnlineTextEntries',
    'acceptsOnlineURL',
    'acceptsOnlineUpload',
    'allDates',
    'allowedExtensions',
    'anonymousGrading',
    'anonymousInstructorAnnotations',
    'anonymousPeerReviews',
    'assignmentGroupId',
    'automaticPeerReviews',
    'canFreeze',
    'defaultToNone',
    'defaultToOnPaper',
    'defaultToOnline',
    'defaultToolName',
    'description',
    'dueAt',
    'dueDateRequired',
    'externalToolCustomParams',
    'externalToolCustomParamsStringified',
    'externalToolData',
    'externalToolLineItem',
    'externalToolLineItemStringified',
    'externalToolDataStringified',
    'externalToolDataStudentLabelText',
    'externalToolNewTab',
    'externalToolUrl',
    'failedToDuplicate',
    'failedToImport',
    'failedToMigrate',
    'freezeOnCopy',
    'frozen',
    'frozenAttributes',
    'gradeGroupStudentsIndividually',
    'gradersAnonymousToGraders',
    'gradingStandardId',
    'gradingType',
    'groupCategoryId',
    'hasDueDate',
    'hasPointsPossible',
    'hideInGradebook',
    'htmlEditUrl',
    'htmlBuildUrl',
    'htmlUrl',
    'iconType',
    'inClosedGradingPeriod',
    'isDefaultTool',
    'isDuplicating',
    'isExternalTool',
    'isGenericExternalTool',
    'isGpaScaled',
    'isImporting',
    'isLetterGraded',
    'isMasteryConnectTool',
    'isMigrating',
    'isMasterCourseChildContent',
    'isNonPlacementExternalTool',
    'isNotGraded',
    'isOnlineSubmission',
    'isOnlyVisibleToOverrides',
    'isPlagiarismPlatformLocked',
    'isQuizLTIAssignment',
    'isSimple',
    'is_quiz_assignment',
    'labelId',
    'lockAt',
    'moderatedGrading',
    'multipleDueDates',
    'name',
    'newQuizzesAssignmentBuildButtonEnabled',
    'hideZeroPointQuizzesOptionEnabled',
    'nonBaseDates',
    'notifyOfUpdate',
    'objectTypeDisplayName',
    'omitFromFinalGrade',
    'originalAssignmentName',
    'peerReviewCount',
    'peerReviews',
    'peerReviewsAssignAt',
    'pointsPossible',
    'position',
    'postToSIS',
    'postToSISEnabled',
    'published',
    'restrictFileExtensions',
    'secureParams',
    'selectedSubmissionTypeToolId',
    'showBuildButton',
    'showGradersAnonymousToGradersCheckbox',
    'singleSectionDueDate',
    'submissionType',
    'submissionTypeSelectionTools',
    'submissionTypesFrozen',
    'turnitinAvailable',
    'turnitinEnabled',
    'unlockAt',
    'vericiteAvailable',
    'vericiteEnabled',
    'importantDates',
    'externalToolIframeWidth',
    'externalToolIframeHeight',
    'isCloningAlignment',
    'failedToCloneAlignment',
    'isUpdateAssignmentSubmissionTypeLaunchButtonEnabled',
  ]
  const hash = {
    id: this.get('id'),
    is_master_course_child_content: this.get('is_master_course_child_content'),
    restricted_by_master_course: this.get('restricted_by_master_course'),
    master_course_restrictions: this.get('master_course_restrictions'),
    restrict_quantitative_data: this.get('restrict_quantitative_data'),
  }
  for (let i = 0, len = fields.length; i < len; i++) {
    const field = fields[i]
    hash[field] = this[field]()
  }
  return hash
}

Assignment.prototype.toJSON = function () {
  let data = Assignment.__super__.toJSON.apply(this, arguments)
  let ref, ref1, ref2
  data = this._filterFrozenAttributes(data)
  if (
    ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
    ((ref1 = ENV.MASTER_COURSE_DATA) != null
      ? (ref2 = ref1.master_course_restrictions) != null
        ? ref2.content
        : void 0
      : void 0)
  ) {
    delete data.description
  }
  if (this.alreadyScoped) {
    return data
  } else {
    return {
      assignment: data,
    }
  }
}

Assignment.prototype.inGradingPeriod = function (gradingPeriod) {
  const dateGroups = this.get('all_dates')
  const gradingPeriodsHelper = new GradingPeriodsHelper(gradingPeriod)
  if (dateGroups) {
    return some(dateGroups.models, dateGroup =>
      gradingPeriodsHelper.isDateInGradingPeriod(dateGroup.dueAt(), gradingPeriod.id)
    )
  } else {
    return gradingPeriodsHelper.isDateInGradingPeriod(tz.parse(this.dueAt()), gradingPeriod.id)
  }
}

Assignment.prototype.search = function (regex, gradingPeriod) {
  let match = regex === '' || this.get('name').match(regex)
  if (match && gradingPeriod) {
    match = this.inGradingPeriod(gradingPeriod)
  }
  if (match) {
    this.set('hidden', false)
    return true
  } else {
    this.set('hidden', true)
    return false
  }
}

Assignment.prototype.endSearch = function () {
  return this.set('hidden', false)
}

Assignment.prototype.parse = function (data) {
  let overrides, turnitin_settings, vericite_settings
  data = Assignment.__super__.parse.call(this, data)
  if ((overrides = data.assignment_overrides) != null) {
    data.assignment_overrides = new AssignmentOverrideCollection(overrides)
  }
  if ((turnitin_settings = data.turnitin_settings) != null) {
    data.turnitin_settings = new TurnitinSettings(turnitin_settings)
  }
  if ((vericite_settings = data.vericite_settings) != null) {
    data.vericite_settings = new VeriCiteSettings(vericite_settings)
  }
  return data
}

// Update the Assignment model instance to not parse results from the
// server. This is a hack to work around the fact that the server will
// always return an overridden due date after a successful PUT request. If
// that is parsed and set on the model, and then another save() is called,
// the assignments default due date will be updated accidentally. Ugh.
Assignment.prototype.doNotParse = function () {
  return (this.parse = function () {
    return {}
  })
}

// @api private
Assignment.prototype._submissionTypes = function () {
  return this.get('submission_types') || []
}

// @api private
Assignment.prototype._hasOnlyType = function (type) {
  const submissionTypes = this._submissionTypes()
  return submissionTypes.length === 1 && submissionTypes[0] === type
}

// @api private
Assignment.prototype._getAssignmentType = function () {
  if (this.isDiscussionTopic()) {
    return 'discussion_topic'
  } else if (this.isPage()) {
    return 'wiki_page'
  } else if (this.isQuiz()) {
    return 'online_quiz'
  } else if (this.isExternalTool()) {
    return 'external_tool'
  } else if (this.isNotGraded()) {
    return 'not_graded'
  } else {
    return 'assignment'
  }
}

Assignment.prototype._filterFrozenAttributes = function (data) {
  let key
  const ref = this.attributes
  for (key in ref) {
    if (!hasProp.call(ref, key)) continue
    if (includes(this.frozenAttributes(), key)) {
      delete data[key]
    }
  }
  if (includes(this.frozenAttributes(), 'title')) {
    delete data.name
  }
  if (includes(this.frozenAttributes(), 'group_category_id')) {
    delete data.grade_group_students_individually
  }
  if (includes(this.frozenAttributes(), 'peer_reviews')) {
    delete data.automatic_peer_reviews
    delete data.peer_review_count
    delete data.peer_reviews_assign_at
  }
  delete data.frozen
  delete data.frozen_attributes
  return data
}

Assignment.prototype.setNullDates = function () {
  this.dueAt(null)
  this.lockAt(null)
  this.unlockAt(null)
  return this
}

Assignment.prototype.publish = function () {
  return this.save('published', true)
}

Assignment.prototype.unpublish = function () {
  return this.save('published', false)
}

Assignment.prototype.disabledMessage = function () {
  return I18n.t("Can't unpublish %{name} if there are student submissions", {
    name: this.get('name'),
  })
}

// caller is original assignment
Assignment.prototype.duplicate = function (callback) {
  const course_id = this.courseID()
  const assignment_id = this.id
  return $.ajaxJSON(
    '/api/v1/courses/' + course_id + '/assignments/' + assignment_id + '/duplicate',
    'POST',
    {},
    callback
  )
}

// caller is failed assignment
Assignment.prototype.duplicate_failed = function (callback) {
  let query_string
  const target_course_id = this.courseID()
  const target_assignment_id = this.id
  const original_course_id = this.originalCourseID()
  const original_assignment_id = this.originalAssignmentID()
  query_string = '?target_assignment_id=' + target_assignment_id
  if (original_course_id !== target_course_id) {
    query_string += '&target_course_id=' + target_course_id
  }
  return $.ajaxJSON(
    '/api/v1/courses/' +
      original_course_id +
      '/assignments/' +
      original_assignment_id +
      '/duplicate' +
      query_string,
    'POST',
    {},
    callback
  )
}

Assignment.prototype.alignment_clone_failed = function (callback) {
  let query_string
  const target_course_id = this.courseID()
  const target_assignment_id = this.id
  const original_course_id = this.originalCourseID()
  const original_assignment_id = this.originalAssignmentID()
  query_string = '?target_assignment_id=' + target_assignment_id
  if (original_course_id !== target_course_id) {
    query_string += '&target_course_id=' + target_course_id
  }
  return $.ajaxJSON(
    '/api/v1/courses/' +
      original_course_id +
      '/assignments/' +
      original_assignment_id +
      '/retry_alignment_clone' +
      query_string,
    'POST',
    {},
    callback
  )
}

// caller is failed migrated assignment
Assignment.prototype.retry_migration = function (callback) {
  const course_id = this.courseID()
  const original_quiz_id = this.originalQuizID()
  const failed_assignment_id = this.get('id')
  return $.ajaxJSON(
    '/api/v1/courses/' +
      course_id +
      '/content_exports?export_type=quizzes2&quiz_id=' +
      original_quiz_id +
      '&failed_assignment_id=' +
      failed_assignment_id +
      '&include[]=migrated_assignment',
    'POST',
    {},
    callback
  )
}

Assignment.prototype.pollUntilFinishedDuplicating = function (interval) {
  if (interval == null) {
    interval = 3000
  }
  return this.pollUntilFinished(interval, this.isDuplicating)
}

Assignment.prototype.pollUntilFinishedCloningAlignment = function (interval) {
  if (interval == null) {
    interval = default_interval
  }
  return this.pollUntilFinished(interval, this.isCloningAlignment)
}

Assignment.prototype.pollUntilFinishedImporting = function (interval) {
  if (interval == null) {
    interval = 3000
  }
  return this.pollUntilFinished(interval, this.isImporting)
}

Assignment.prototype.pollUntilFinishedMigrating = function (interval) {
  if (interval == null) {
    interval = 3000
  }
  return this.pollUntilFinished(interval, this.isMigrating)
}

Assignment.prototype.pollUntilFinishedLoading = function (interval) {
  if (interval == null) {
    interval = 3000
  }
  if (this.isDuplicating()) {
    return this.pollUntilFinishedDuplicating(interval)
  } else if (this.isImporting()) {
    return this.pollUntilFinishedImporting(interval)
  } else if (this.isMigrating()) {
    return this.pollUntilFinishedMigrating(interval)
  } else if (this.isCloningAlignment()) {
    return this.pollUntilFinishedCloningAlignment(interval)
  }
}

Assignment.prototype.pollUntilFinished = function (interval, isFinished) {
  // TODO: implement pandapub streaming updates
  const poller = new PandaPubPoller(
    interval,
    interval * 5,
    (function (_this) {
      return function (done) {
        return _this.fetch().always(function () {
          done()
          if (!isFinished()) {
            return poller.stop()
          }
        })
      }
    })(this)
  )
  return poller.start()
}

Assignment.prototype.isOnlyVisibleToOverrides = function (override_flag) {
  if (!(arguments.length > 0)) {
    if (ENV.FEATURES?.differentiated_modules && this.get('visible_to_everyone') != null) {
      return !this.get('visible_to_everyone')
    }
    return this.get('only_visible_to_overrides') || false
  }
  return this.set('only_visible_to_overrides', override_flag)
}

Assignment.prototype.isRestrictedByMasterCourse = function () {
  return this.get('is_master_course_child_content') && this.get('restricted_by_master_course')
}

Assignment.prototype.showGradersAnonymousToGradersCheckbox = function () {
  return this.moderatedGrading() && this.get('grader_comments_visible_to_graders')
}

Assignment.prototype.quizzesRespondusEnabled = function () {
  return this.get('require_lockdown_browser') && this.isQuizLTIAssignment() && isStudent()
}

export default Assignment

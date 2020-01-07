#
# Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import {Model} from 'Backbone'
import DefaultUrlMixin from '../backbone-ext/DefaultUrlMixin'
import TurnitinSettings from './TurnitinSettings'
import VeriCiteSettings from './VeriCiteSettings'
import DateGroup from './DateGroup'
import AssignmentOverrideCollection from '../collections/AssignmentOverrideCollection'
import DateGroupCollection from '../collections/DateGroupCollection'
import I18n from 'i18n!models_Assignment'
import GradingPeriodsHelper from 'jsx/grading/helpers/GradingPeriodsHelper'
import tz from 'timezone'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import PandaPubPoller from '../util/PandaPubPoller'
import { matchingToolUrls } from './LtiAssignmentHelpers'

isAdmin = () ->
  _.includes(ENV.current_user_roles, 'admin')

isStudent = () ->
  _.includes(ENV.current_user_roles, 'student')

export default class Assignment extends Model
  @mixin DefaultUrlMixin
  resourceName: 'assignments'

  urlRoot: -> @_defaultUrl()

  defaults:
    "publishable": true
    "hidden": false
    "unpublishable": true

  initialize: ->
    if (overrides = @get('assignment_overrides'))?
      @set 'assignment_overrides', new AssignmentOverrideCollection(overrides)
    if (turnitin_settings = @get('turnitin_settings'))?
      @set 'turnitin_settings', new TurnitinSettings(turnitin_settings),
        silent: true
    if (vericite_settings = @get('vericite_settings'))?
      @set 'vericite_settings', new VeriCiteSettings(vericite_settings),
        silent: true
    if (all_dates = @get('all_dates'))?
      @set 'all_dates', new DateGroupCollection(all_dates)
    if (@postToSISEnabled())
      if !@get('id') && @get('post_to_sis') != false
        @set 'post_to_sis', !!ENV?.POST_TO_SIS_DEFAULT

  isQuiz: => @_hasOnlyType 'online_quiz'
  isDiscussionTopic: => @_hasOnlyType 'discussion_topic'
  isPage: => @_hasOnlyType 'wiki_page'
  isExternalTool: => @_hasOnlyType 'external_tool'

  defaultToolName: => ENV.DEFAULT_ASSIGNMENT_TOOL_NAME && escape(ENV.DEFAULT_ASSIGNMENT_TOOL_NAME).replace(/%20/g, ' ')
  defaultToolUrl: => ENV.DEFAULT_ASSIGNMENT_TOOL_URL
  isNotGraded: => @_hasOnlyType 'not_graded'
  isAssignment: =>
    ! _.includes @_submissionTypes(), 'online_quiz', 'discussion_topic',
      'not_graded', 'external_tool'

  assignmentType: (type) =>
    return @_getAssignmentType() unless arguments.length > 0
    if type == 'assignment'
      @set 'submission_types', [ 'none' ]
    else
      @set 'submission_types', [ type ]

  dueAt: (date) =>
    return @get 'due_at' unless arguments.length > 0
    @set 'due_at', date

  unlockAt: (date) =>
    return @get 'unlock_at' unless arguments.length > 0
    @set 'unlock_at', date

  lockAt: (date)  =>
    return @get 'lock_at' unless arguments.length > 0
    @set 'lock_at', date

  dueDateRequired: (newDueDateRequired) =>
    return @get 'dueDateRequired' unless arguments.length > 0
    @set 'dueDateRequired', newDueDateRequired

  description: (newDescription) =>
    return @get 'description' unless arguments.length > 0
    @set 'description', newDescription

  name: (newName) =>
    return @get 'name' unless arguments.length > 0
    @set 'name', newName

  pointsPossible: (points) =>
    return @get('points_possible') || 0 unless arguments.length > 0
    # if the incoming value is valid, set the field to the numeric value
    # if not, set to the incoming string and let validation handle it later
    if(numberHelper.validate(points))
      @set 'points_possible', numberHelper.parse(points)
    else
      @set 'points_possible', points

  secureParams: =>
    @get('secure_params')

  assignmentGroupId: (assignment_group_id) =>
    return @get 'assignment_group_id' unless arguments.length > 0
    @set 'assignment_group_id', assignment_group_id

  canFreeze: =>
    @get('frozen_attributes')? && !@frozen() && !@isQuizLTIAssignment()

  canDelete: =>
    not @inClosedGradingPeriod() and not @frozen()

  canMove: =>
    not @inClosedGradingPeriod() and not _.includes(@frozenAttributes(), 'assignment_group_id')

  freezeOnCopy: =>
    @get('freeze_on_copy')

  frozen: =>
    @get('frozen')

  frozenAttributes: =>
    @get('frozen_attributes') || []

  inClosedGradingPeriod: =>
    return false if isAdmin()
    @get('in_closed_grading_period')

  gradingType: (gradingType) =>
    return @get('grading_type') || 'points' unless gradingType
    @set 'grading_type', gradingType

  omitFromFinalGrade: (omitFromFinalGradeBoolean) =>
    return @get 'omit_from_final_grade' unless arguments.length > 0
    @set 'omit_from_final_grade', omitFromFinalGradeBoolean

  courseID: => @get('course_id')

  submissionTypes: (submissionTypes) =>
    return @_submissionTypes() unless arguments.length > 0
    @set 'submission_types', submissionTypes

  isNewAssignment: =>
    !@name()

  shouldShowDefaultTool: =>
    return false if !@defaultToolUrl()
    @defaultToolSelected() ||
      @isQuickCreateDefaultTool() ||
      @isNewAssignment()

  isDefaultTool: =>
    @submissionType() == 'external_tool' && @shouldShowDefaultTool()

  defaultToNone: =>
    @submissionType() == 'none' && !@shouldShowDefaultTool()

  defaultToOnline: =>
    @submissionType() == 'online' && !@shouldShowDefaultTool()

  defaultToOnPaper: =>
    @submissionType() == 'on_paper' && !@shouldShowDefaultTool()

  isQuickCreateDefaultTool: =>
    @submissionTypes().includes('default_external_tool')

  defaultToolSelected: =>
    matchingToolUrls(
      @defaultToolUrl(),
      @externalToolUrl()
    )

  isNonDefaultExternalTool: =>
    # The assignment is type 'external_tool' and the default tool is not selected
    # or chosen from the "quick create" assignment index modal.
    @submissionType() == 'external_tool' && !@isDefaultTool()

  submissionType: =>
    submissionTypes = @_submissionTypes()
    if _.includes(submissionTypes, 'none') || submissionTypes.length == 0 then 'none'
    else if _.includes submissionTypes, 'on_paper' then 'on_paper'
    else if _.includes submissionTypes, 'external_tool' then 'external_tool'
    else if _.includes submissionTypes, 'default_external_tool' then 'external_tool'
    else 'online'

  expectsSubmission: =>
    submissionTypes = @_submissionTypes()
    submissionTypes.length > 0 && !_.includes(submissionTypes, "") && !_.includes(submissionTypes, 'none') && !_.includes(submissionTypes, 'not_graded') && !_.includes(submissionTypes, 'on_paper') && !_.includes(submissionTypes, 'external_tool')

  allowedToSubmit: =>
    submissionTypes = @_submissionTypes()
    @expectsSubmission() && !@get('locked_for_user') && !_.includes(submissionTypes, 'online_quiz') && !_.includes(submissionTypes, 'attendance')

  hasSubmittedSubmissions: =>
    @get('has_submitted_submissions')

  withoutGradedSubmission: =>
    sub = @get('submission')
    !sub? || sub.withoutGradedSubmission()

  acceptsOnlineUpload: =>
    !! _.includes @_submissionTypes(), 'online_upload'

  acceptsOnlineURL: =>
    !! _.includes @_submissionTypes(), 'online_url'

  acceptsMediaRecording: =>
    !! _.includes @_submissionTypes(), 'media_recording'

  acceptsOnlineTextEntries: =>
    !! _.includes @_submissionTypes(), 'online_text_entry'

  isOnlineSubmission: =>
    _.some @_submissionTypes(), (thing) ->
      thing in ['online', 'online_text_entry',
        'media_recording', 'online_url', 'online_upload']

  postToSIS: (postToSisBoolean) =>
    return @get 'post_to_sis' unless arguments.length > 0
    @set 'post_to_sis', postToSisBoolean

  moderatedGrading: (enabled) =>
    return @get('moderated_grading') or false unless arguments.length > 0
    @set('moderated_grading', enabled)

  anonymousInstructorAnnotations: (anonymousInstructorAnnotationsBoolean) =>
    return @get 'anonymous_instructor_annotations' unless arguments.length > 0
    @set 'anonymous_instructor_annotations', anonymousInstructorAnnotationsBoolean

  anonymousGrading: (anonymousGradingBoolean) =>
    return @get 'anonymous_grading' unless arguments.length > 0
    @set 'anonymous_grading', anonymousGradingBoolean

  gradersAnonymousToGraders: (anonymousGraders) =>
    return @get('graders_anonymous_to_graders') unless arguments.length > 0
    @set 'graders_anonymous_to_graders', anonymousGraders

  graderCommentsVisibleToGraders: (commentsVisible) =>
    return !!@get('grader_comments_visible_to_graders') unless arguments.length > 0
    @set 'grader_comments_visible_to_graders', commentsVisible

  peerReviews: (peerReviewBoolean) =>
    return @get 'peer_reviews' unless arguments.length > 0
    @set 'peer_reviews', peerReviewBoolean

  anonymousPeerReviews: (anonymousPeerReviewBoolean) =>
    return @get 'anonymous_peer_reviews' unless arguments.length > 0
    @set 'anonymous_peer_reviews', anonymousPeerReviewBoolean

  automaticPeerReviews: (autoPeerReviewBoolean) =>
    return @get 'automatic_peer_reviews' unless arguments.length > 0
    @set 'automatic_peer_reviews', autoPeerReviewBoolean

  peerReviewCount:(peerReviewCount) =>
    return @get('peer_review_count') || 0 unless arguments.length > 0
    @set 'peer_review_count', peerReviewCount

  peerReviewsAssignAt: (date)  =>
    return @get('peer_reviews_assign_at') || null unless arguments.length > 0
    @set 'peer_reviews_assign_at', date

  intraGroupPeerReviews: ->
    @get('intra_group_peer_reviews')

  notifyOfUpdate: (notifyOfUpdateBoolean) =>
    return @get 'notify_of_update' unless arguments.length > 0
    @set 'notify_of_update', notifyOfUpdateBoolean

  restrictFileExtensions: => !!@allowedExtensions()

  allowedExtensions: (extensionsList) =>
    return @get('allowed_extensions') unless arguments.length > 0
    @set 'allowed_extensions', extensionsList

  turnitinAvailable: =>
    typeof @get('turnitin_enabled') != 'undefined'

  vericiteAvailable: =>
    typeof @get('vericite_enabled') != 'undefined'

  gradeGroupStudentsIndividually: (setting) =>
    return @get('grade_group_students_individually') unless arguments.length > 0
    @set 'grade_group_students_individually', setting

  turnitinEnabled: (setting) =>
    if arguments.length == 0
      if @get( 'turnitin_enabled' ) == undefined
        false
      else
        !!@get( 'turnitin_enabled' )
    else
      @set( 'turnitin_enabled', setting )

  vericiteEnabled: (setting) =>
    if arguments.length == 0
      if @get( 'vericite_enabled' ) == undefined
        false
      else
        !!@get( 'vericite_enabled' )
    else
      @set( 'vericite_enabled', setting )

  groupCategoryId: (id) =>
    return @get( 'group_category_id' ) unless arguments.length > 0
    @set 'group_category_id', id

  canGroup: -> !@get('has_submitted_submissions')

  gradingStandardId: (id) =>
    return @get('grading_standard_id') unless arguments.length > 0
    @set 'grading_standard_id', id

  externalToolUrl: (url) =>
    tagAttributes = @get('external_tool_tag_attributes') || {}
    return tagAttributes.url unless arguments.length > 0
    tagAttributes.url = url
    @set 'external_tool_tag_attributes', tagAttributes

  externalToolNewTab: (b) =>
    tagAttributes = @get('external_tool_tag_attributes') || {}
    return tagAttributes.new_tab unless arguments.length > 0
    tagAttributes.new_tab = b
    @set 'external_tool_tag_attributes', tagAttributes

  isSimple: =>
    overrides = @get('assignment_overrides')
    @gradingType() == 'points' and
      @submissionType() == 'none' and
      !@groupCategoryId() and
      !@peerReviews() and
      !@frozen() and
      (!overrides or overrides.isSimple())

  isLetterGraded: =>
    @gradingType() == 'letter_grade'

  isGpaScaled: =>
    @gradingType() == 'gpa_scale'

  published: (newPublished) =>
    return @get 'published' unless arguments.length > 0
    @set 'published', newPublished

  useNewQuizIcon: () =>
    ENV.FLAGS && ENV.FLAGS.newquizzes_on_quiz_page && @isQuizLTIAssignment()

  position: (newPosition) ->
    return @get('position') || 0 unless arguments.length > 0
    @set 'position', newPosition

  iconType: =>
    return 'quiz icon-Solid' if @useNewQuizIcon()
    return 'quiz' if @isQuiz()
    return 'discussion' if @isDiscussionTopic()
    return 'document' if @isPage()
    return 'assignment'

  objectType: =>
    return 'Quiz' if @isQuiz()
    return 'Discussion' if @isDiscussionTopic()
    return 'WikiPage' if @isPage()
    return 'Assignment'

  objectTypeDisplayName: ->
    return I18n.t('Quiz') if @isQuiz()
    return I18n.t('Discussion Topic') if @isDiscussionTopic()
    return I18n.t('Page') if @isPage()
    return I18n.t('Assignment')

  htmlUrl: =>
    @get 'html_url'

  htmlEditUrl: =>
    "#{@get 'html_url'}/edit"

  labelId: =>
    return @id

  postToSISEnabled: =>
    return ENV.POST_TO_SIS

  postToSISName: =>
    return ENV.SIS_NAME

  sisIntegrationSettingsEnabled: =>
    return ENV.SIS_INTEGRATION_SETTINGS_ENABLED

  maxNameLength: =>
    return ENV.MAX_NAME_LENGTH

  maxNameLengthRequiredForAccount: =>
    return ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT

  dueDateRequiredForAccount: =>
    return ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT

  defaultDates: =>
    group = new DateGroup
      due_at:    @get("due_at")
      unlock_at: @get("unlock_at")
      lock_at:   @get("lock_at")

  multipleDueDates: =>
    count = @get("all_dates_count")
    if count && count > 1
      true
    else
      dateGroups = @get("all_dates")
      dateGroups && dateGroups.length > 1

  hasDueDate: =>
    !@isPage()

  hasPointsPossible: =>
    !@isQuiz() && !@isPage()

  nonBaseDates: =>
    dateGroups = @get("all_dates")
    return false unless dateGroups
    withouBase = _.filter(dateGroups.models, (dateGroup) =>
      dateGroup && !dateGroup.get("base")
    )
    withouBase.length > 0

  allDates: =>
    groups = @get("all_dates")
    models = (groups and groups.models) or []
    result = _.map models, (group) -> group.toJSON()

  singleSectionDueDate: =>
    if !@multipleDueDates() && !@dueAt()
      allDates = @allDates()
      for section in allDates
        if section.dueAt
          return section.dueAt.toISOString()
    else
      return @dueAt()

  canDuplicate: =>
    @get('can_duplicate')

  isDuplicating: =>
    @get('workflow_state') == 'duplicating'

  isMigrating: =>
    @get('workflow_state') == 'migrating'

  failedToDuplicate: =>
    @get('workflow_state') == 'failed_to_duplicate'

  failedToMigrate: =>
    @get('workflow_state') == 'failed_to_migrate'

  originalCourseID: =>
    @get('original_course_id')

  originalQuizID: =>
    @get('original_quiz_id')

  originalAssignmentID: =>
    @get('original_assignment_id')

  originalAssignmentName: =>
    @get('original_assignment_name')

  is_quiz_assignment: =>
    @get('is_quiz_assignment')

  isQuizLTIAssignment: =>
    @get('is_quiz_lti_assignment')

  isImporting: =>
    @get('workflow_state') == 'importing'

  failedToImport: =>
    @get('workflow_state') == 'failed_to_import'

  submissionTypesFrozen: =>
    _.includes(@frozenAttributes(), 'submission_types')

  toView: =>
    fields = [
      'name', 'dueAt', 'description', 'pointsPossible', 'lockAt', 'unlockAt',
      'gradingType', 'notifyOfUpdate', 'peerReviews', 'automaticPeerReviews',
      'peerReviewCount', 'peerReviewsAssignAt', 'anonymousPeerReviews',
      'acceptsOnlineUpload', 'acceptsMediaRecording', 'submissionType',
      'acceptsOnlineTextEntries', 'acceptsOnlineURL', 'allowedExtensions',
      'restrictFileExtensions', 'isOnlineSubmission', 'isNotGraded',
      'isExternalTool', 'externalToolUrl', 'externalToolNewTab',
      'turnitinAvailable', 'turnitinEnabled', 'vericiteAvailable',
      'vericiteEnabled', 'gradeGroupStudentsIndividually', 'groupCategoryId',
      'frozen', 'frozenAttributes', 'freezeOnCopy', 'canFreeze', 'isSimple',
      'gradingStandardId', 'isLetterGraded', 'isGpaScaled',
      'assignmentGroupId', 'iconType', 'published', 'htmlUrl', 'htmlEditUrl',
      'labelId', 'position', 'postToSIS', 'multipleDueDates', 'nonBaseDates',
      'allDates', 'hasDueDate', 'hasPointsPossible', 'singleSectionDueDate',
      'moderatedGrading', 'postToSISEnabled', 'isOnlyVisibleToOverrides',
      'omitFromFinalGrade', 'isDuplicating', 'isMigrating', 'failedToDuplicate',
      'originalAssignmentName', 'is_quiz_assignment', 'isQuizLTIAssignment',
      'isImporting', 'failedToImport', 'failedToMigrate',
      'secureParams', 'inClosedGradingPeriod', 'dueDateRequired',
      'submissionTypesFrozen', 'anonymousInstructorAnnotations',
      'anonymousGrading', 'gradersAnonymousToGraders', 'showGradersAnonymousToGradersCheckbox',
      'defaultToolName', 'isDefaultTool', 'isNonDefaultExternalTool', 'defaultToNone',
      'defaultToOnline', 'defaultToOnPaper', 'objectTypeDisplayName'
    ]

    hash =
      id: @get('id'),
      is_master_course_child_content: @get('is_master_course_child_content'),
      restricted_by_master_course: @get('restricted_by_master_course'),
      master_course_restrictions: @get('master_course_restrictions')
    for field in fields
      hash[field] = @[field]()
    hash

  toJSON: ->
    data = super
    data = @_filterFrozenAttributes(data)
    delete data.description if (ENV.MASTER_COURSE_DATA?.is_master_course_child_content && ENV.MASTER_COURSE_DATA?.master_course_restrictions?.content)
    if @alreadyScoped then data else { assignment: data }

  inGradingPeriod: (gradingPeriod) ->
    dateGroups = @get("all_dates")
    gradingPeriodsHelper = new GradingPeriodsHelper(gradingPeriod)
    if dateGroups
      _.some dateGroups.models, (dateGroup) =>
        gradingPeriodsHelper.isDateInGradingPeriod(dateGroup.dueAt(), gradingPeriod.id)
    else
      gradingPeriodsHelper.isDateInGradingPeriod(tz.parse(@dueAt()), gradingPeriod.id)

  search: (regex, gradingPeriod) ->
    match = regex == "" || @get('name').match(regex)
    match = @inGradingPeriod(gradingPeriod) if match && gradingPeriod
    if match
      @set 'hidden', false
      return true
    else
      @set 'hidden', true
      return false

  endSearch: ->
    @set 'hidden', false

  parse: (data) ->
    data = super data
    if (overrides = data.assignment_overrides)?
      data.assignment_overrides = new AssignmentOverrideCollection overrides
    if (turnitin_settings = data.turnitin_settings)?
      data.turnitin_settings = new TurnitinSettings turnitin_settings
    if (vericite_settings = data.vericite_settings)?
      data.vericite_settings = new VeriCiteSettings vericite_settings
    data

  # Update the Assignment model instance to not parse results from the
  # server. This is a hack to work around the fact that the server will
  # always return an overridden due date after a successful PUT request. If
  # that is parsed and set on the model, and then another save() is called,
  # the assignments default due date will be updated accidentally. Ugh.
  doNotParse: ->
    @parse = -> {}

  # @api private
  _submissionTypes: =>
    @get('submission_types') || []

  # @api private
  _hasOnlyType: (type) =>
    submissionTypes = @_submissionTypes()
    submissionTypes.length == 1 && submissionTypes[0] == type

  # @api private
  _getAssignmentType: =>
    if @isDiscussionTopic() then 'discussion_topic'
    else if @isPage() then 'wiki_page'
    else if @isQuiz() then 'online_quiz'
    else if @isExternalTool() then 'external_tool'
    else if @isNotGraded() then 'not_graded'
    else 'assignment'

  _filterFrozenAttributes: (data) =>
    for own key, value of @attributes
      if _.includes(@frozenAttributes(), key)
        delete data[key]
    if _.includes(@frozenAttributes(), "title")
      delete data.name
    if _.includes(@frozenAttributes(), "group_category_id")
      delete data.grade_group_students_individually
    if _.includes(@frozenAttributes(), "peer_reviews")
      delete data.automatic_peer_reviews
      delete data.peer_review_count
      delete data.peer_reviews_assign_at
    delete data.frozen
    delete data.frozen_attributes
    data

  setNullDates: =>
    @dueAt null
    @lockAt null
    @unlockAt null
    this

  publish: -> @save("published", true)
  unpublish: -> @save("published", false)

  disabledMessage: ->
    I18n.t("Can't unpublish %{name} if there are student submissions", name: @get('name'))

  # caller is original assignment
  duplicate: (callback) =>
    course_id = @courseID()
    assignment_id = @id
    $.ajaxJSON "/api/v1/courses/#{course_id}/assignments/#{assignment_id}/duplicate", 'POST',
      {}, callback

  # caller is failed assignment
  duplicate_failed: (callback) =>
    target_course_id = @courseID()
    target_assignment_id = @id
    original_course_id = @originalCourseID()
    original_assignment_id = @originalAssignmentID()
    query_string = "?target_assignment_id=#{target_assignment_id}"
    if (original_course_id != target_course_id) # when it's a course copy failure
      query_string += "&target_course_id=#{target_course_id}"
    $.ajaxJSON "/api/v1/courses/#{original_course_id}/assignments/#{original_assignment_id}/duplicate#{query_string}",
      'POST', {}, callback

  # caller is failed migrated assignment
  retry_migration: (callback) =>
    course_id = @courseID()
    original_quiz_id = @originalQuizID()
    failed_assignment_id = @get('id')
    $.ajaxJSON "/api/v1/courses/#{course_id}/content_exports?export_type=quizzes2&quiz_id=#{original_quiz_id}&failed_assignment_id=#{failed_assignment_id}&include[]=migrated_assignment",
      'POST', {}, callback

  pollUntilFinishedDuplicating: (interval = 3000) =>
    @pollUntilFinished(interval, @isDuplicating)

  pollUntilFinishedImporting: (interval = 3000) =>
    @pollUntilFinished(interval, @isImporting)

  pollUntilFinishedMigrating: (interval = 3000) =>
    @pollUntilFinished(interval, @isMigrating)

  pollUntilFinishedLoading: (interval = 3000) =>
    if @isDuplicating()
      @pollUntilFinishedDuplicating(interval)
    else if @isImporting()
      @pollUntilFinishedImporting(interval)
    else if @isMigrating()
      @pollUntilFinishedMigrating(interval)

  pollUntilFinished: (interval, isFinished) =>
    # TODO: implement pandapub streaming updates
    poller = new PandaPubPoller interval, interval * 5, (done) =>
      @fetch().always =>
        done()
        poller.stop() unless isFinished()
    poller.start()

  isOnlyVisibleToOverrides: (override_flag) ->
    return @get('only_visible_to_overrides') || false unless arguments.length > 0
    @set 'only_visible_to_overrides', override_flag

  isRestrictedByMasterCourse: ->
    @get('is_master_course_child_content') && @get('restricted_by_master_course')

  showGradersAnonymousToGradersCheckbox: =>
    @moderatedGrading() && @get('grader_comments_visible_to_graders')

  quizzesRespondusEnabled: =>
    @get('require_lockdown_browser') && @isQuizLTIAssignment() && isStudent()

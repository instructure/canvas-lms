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

define [
  'jquery'
  'underscore'
  'Backbone'
  '../backbone-ext/DefaultUrlMixin'
  '../models/TurnitinSettings'
  '../models/VeriCiteSettings'
  '../models/DateGroup'
  '../collections/AssignmentOverrideCollection'
  '../collections/DateGroupCollection'
  'i18n!assignments'
  'jsx/grading/helpers/GradingPeriodsHelper'
  'timezone'
  'jsx/shared/helpers/numberHelper'
], ($, _, {Model}, DefaultUrlMixin, TurnitinSettings, VeriCiteSettings, DateGroup, AssignmentOverrideCollection,
    DateGroupCollection, I18n, GradingPeriodsHelper, tz, numberHelper) ->

  isAdmin = () ->
    _.contains(ENV.current_user_roles, 'admin')

  class Assignment extends Model
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
    isNotGraded: => @_hasOnlyType 'not_graded'
    isAssignment: =>
      ! _.include @_submissionTypes(), 'online_quiz', 'discussion_topic',
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
      not @inClosedGradingPeriod() and not _.include(@frozenAttributes(), 'assignment_group_id')

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

    submissionType: =>
      submissionTypes = @_submissionTypes()
      if _.include(submissionTypes, 'none') || submissionTypes.length == 0 then 'none'
      else if _.include submissionTypes, 'on_paper' then 'on_paper'
      else if _.include submissionTypes, 'external_tool' then 'external_tool'
      else 'online'

    expectsSubmission: =>
      submissionTypes = @_submissionTypes()
      submissionTypes.length > 0 && !_.include(submissionTypes, "") && !_.include(submissionTypes, 'none') && !_.include(submissionTypes, 'not_graded') && !_.include(submissionTypes, 'on_paper') && !_.include(submissionTypes, 'external_tool')

    allowedToSubmit: =>
      submissionTypes = @_submissionTypes()
      @expectsSubmission() && !@get('locked_for_user') && !_.include(submissionTypes, 'online_quiz') && !_.include(submissionTypes, 'attendance')

    hasSubmittedSubmissions: =>
      @get('has_submitted_submissions')

    withoutGradedSubmission: =>
      sub = @get('submission')
      !sub? || sub.withoutGradedSubmission()

    acceptsOnlineUpload: =>
      !! _.include @_submissionTypes(), 'online_upload'

    acceptsOnlineURL: =>
      !! _.include @_submissionTypes(), 'online_url'

    acceptsMediaRecording: =>
      !! _.include @_submissionTypes(), 'media_recording'

    acceptsOnlineTextEntries: =>
      !! _.include @_submissionTypes(), 'online_text_entry'

    isOnlineSubmission: =>
      _.any @_submissionTypes(), (thing) ->
        thing in ['online', 'online_text_entry',
          'media_recording', 'online_url', 'online_upload']

    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

    moderatedGrading: (moderatedGradingBoolean) =>
      return @get 'moderated_grading' unless arguments.length > 0
      @set 'moderated_grading', moderatedGradingBoolean

    anonymousInstructorAnnotations: (anonymousInstructorAnnotationsBoolean) =>
      return @get 'anonymous_instructor_annotations' unless arguments.length > 0
      @set 'anonymous_instructor_annotations', anonymousInstructorAnnotationsBoolean

    anonymousGrading: (anonymousGradingBoolean) =>
      return @get 'anonymous_grading' unless arguments.length > 0
      @set 'anonymous_grading', anonymousGradingBoolean

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

    position: (newPosition) ->
      return @get('position') || 0 unless arguments.length > 0
      @set 'position', newPosition

    iconType: =>
      return 'quiz' if @isQuiz()
      return 'discussion' if @isDiscussionTopic()
      return 'document' if @isPage()
      return 'assignment'

    objectType: =>
      return 'Quiz' if @isQuiz()
      return 'Discussion' if @isDiscussionTopic()
      return 'WikiPage' if @isPage()
      return 'Assignment'

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

    is_quiz_assignment: =>
      @get('is_quiz_assignment')

    isQuizLTIAssignment: =>
      @get('is_quiz_lti_assignment')

    submissionTypesFrozen: =>
      _.include(@frozenAttributes(), 'submission_types')

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
        'omitFromFinalGrade', 'is_quiz_assignment', 'isQuizLTIAssignment',
        'secureParams', 'inClosedGradingPeriod', 'dueDateRequired', 'submissionTypesFrozen',
        'anonymousInstructorAnnotations', 'anonymousGrading'
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
        _.any dateGroups.models, (dateGroup) =>
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
        if _.contains(@frozenAttributes(), key)
          delete data[key]
      if _.contains(@frozenAttributes(), "title")
        delete data.name
      if _.contains(@frozenAttributes(), "group_category_id")
        delete data.grade_group_students_individually
      if _.contains(@frozenAttributes(), "peer_reviews")
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

    duplicate: (callback) =>
      course_id = @courseID()
      assignment_id = @id
      $.ajaxJSON "/api/v1/courses/#{course_id}/assignments/#{assignment_id}/duplicate", 'POST',
        {}, callback

    isOnlyVisibleToOverrides: (override_flag) ->
      return @get('only_visible_to_overrides') || false unless arguments.length > 0
      @set 'only_visible_to_overrides', override_flag

    isRestrictedByMasterCourse: ->
      @get('is_master_course_child_content') && @get('restricted_by_master_course')

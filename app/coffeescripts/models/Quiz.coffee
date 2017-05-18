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

define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Assignment'
  'compiled/models/DateGroup'
  'compiled/collections/AssignmentOverrideCollection'
  'compiled/collections/DateGroupCollection'
  'str/pluralize'
  'i18n!quizzes'
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers' # $.underscore
], ($, _, Backbone, Assignment, DateGroup, AssignmentOverrideCollection, DateGroupCollection, pluralize, I18n) ->

  class Quiz extends Backbone.Model
    resourceName: 'quizzes'

    defaults:
      due_at: null
      unlock_at: null
      lock_at: null
      unpublishable: true
      points_possible: null
      post_to_sis: false

    initialize: (attributes, options = {}) ->
      super
      @initAssignment()
      @initAssignmentOverrides()
      @initUrls()
      @initTitleLabel()
      @initUnpublishable()
      @initQuestionsCount()
      @initPointsCount()
      @initAllDates()


    # initialize attributes
    initAssignment: ->
      if @attributes.assignment
        @set 'assignment', new Assignment(@attributes.assignment)
      @set 'post_to_sis_enabled', @postToSISEnabled()

    initAssignmentOverrides: ->
      if @attributes.assignment_overrides
        overrides = new AssignmentOverrideCollection(@attributes.assignment_overrides)
        @set 'assignment_overrides', overrides, silent: true

    initUrls: ->
      if @get 'html_url'
        @set 'base_url', @get('html_url').replace(/quizzes\/\d+/, "quizzes")

        @set 'url',           "#{@get 'base_url'}/#{@get 'id'}"
        @set 'edit_url',      "#{@get 'base_url'}/#{@get 'id'}/edit"
        @set 'publish_url',   "#{@get 'base_url'}/publish"
        @set 'unpublish_url', "#{@get 'base_url'}/unpublish"
        @set 'toggle_post_to_sis_url', "#{@get 'base_url'}/#{@get 'id'}/toggle_post_to_sis"

    initTitleLabel: ->
      @set 'title_label', @get('title') or @get('readable_type')

    initUnpublishable: ->
      @set('unpublishable', false) if @get('can_unpublish') == false and @get('published')

    initQuestionsCount: ->
      cnt = @get 'question_count'
      @set 'question_count_label', I18n.t('question_count', 'Question', count: cnt)

    initPointsCount: ->
      pts = @get 'points_possible'
      text = ''
      if pts && pts > 0 && !@isUngradedSurvey()
        text = I18n.t('assignment_points_possible', 'pt', count: pts)
      @set 'possible_points_label', text

    isUngradedSurvey: ->
      @get('quiz_type') == "survey"

    initAllDates: ->
      if (allDates = @get('all_dates'))?
        @set 'all_dates', new DateGroupCollection(allDates)

    # publishing

    publish: =>
      @set 'published', true
      $.ajaxJSON(@get('publish_url'), 'POST', 'quizzes': [@get 'id'])

    unpublish: =>
      @set 'published', false
      $.ajaxJSON(@get('unpublish_url'), 'POST', 'quizzes': [@get 'id'])

    disabledMessage: ->
      I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")

    # methods needed by views

    dueAt: (date) =>
      return @get 'due_at' unless arguments.length > 0
      @set 'due_at', date

    unlockAt: (date) =>
      return @get 'unlock_at' unless arguments.length > 0
      @set 'unlock_at', date

    lockAt: (date)  =>
      return @get 'lock_at' unless arguments.length > 0
      @set 'lock_at', date

    name: (newName) =>
      return @get 'title' unless arguments.length > 0
      @set 'title', newName

    htmlUrl: =>
      @get 'url'

    defaultDates: =>
      group = new DateGroup
        due_at:    @get("due_at")
        unlock_at: @get("unlock_at")
        lock_at:   @get("lock_at")

    multipleDueDates: =>
      dateGroups = @get("all_dates")
      dateGroups && dateGroups.length > 1

    nonBaseDates: =>
      dateGroups = @get("all_dates")
      return false unless dateGroups
      withouBase = _.filter(dateGroups, (dateGroup) ->
        dateGroup && !dateGroup.get("base")
      )
      withouBase.length > 0

    allDates: =>
      groups = @get("all_dates")
      models = (groups and groups.models) or []
      result = _.map models, (group) -> group.toJSON()

    singleSectionDueDate: =>
      _.find(@allDates(), 'dueAt')?.dueAt.toISOString() || @dueAt()

    isOnlyVisibleToOverrides: (overrideFlag) ->
      return @get('only_visible_to_overrides') || false unless arguments.length > 0
      @set('only_visible_to_overrides', overrideFlag)

    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

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

    toView: =>
      fields = [
        'htmlUrl', 'multipleDueDates', 'nonBaseDates', 'allDates', 'dueAt', 'lockAt', 'unlockAt', 'singleSectionDueDate'
      ]
      hash = id: @get 'id'
      for field in fields
        hash[field] = @[field]()
      hash

    postToSISEnabled: =>
      return ENV.FLAGS && ENV.FLAGS.post_to_sis_enabled

    objectType: =>
      return 'Quiz'

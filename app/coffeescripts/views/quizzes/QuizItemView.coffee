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
  'i18n!quizzes.index'
  'jquery'
  'underscore'
  'Backbone'
  'jsx/shared/conditional_release/CyoeHelper'
  '../PublishIconView'
  '../LockIconView'
  '../assignments/DateDueColumnView'
  '../assignments/DateAvailableColumnView'
  '../SisButtonView'
  'jst/quizzes/QuizItemView'
  'jquery.disableWhileLoading'
], (I18n, $, _, Backbone, CyoeHelper, PublishIconView, LockIconView, DateDueColumnView, DateAvailableColumnView, SisButtonView, template) ->

  class ItemView extends Backbone.View

    template: template

    tagName:   'li'
    className: 'quiz'

    @child 'publishIconView',         '[data-view=publish-icon]'
    @child 'lockIconView',            '[data-view=lock-icon]'
    @child 'dateDueColumnView',       '[data-view=date-due]'
    @child 'dateAvailableColumnView', '[data-view=date-available]'
    @child 'sisButtonView',           '[data-view=sis-button]'

    events:
      'click': 'clickRow'
      'click .delete-item': 'onDelete'
      'click .migrate': 'migrateQuiz'

    messages:
      confirm: I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?')
      multipleDates: I18n.t('multiple_due_dates', 'Multiple Dates')
      deleteSuccessful: I18n.t('flash.removed', 'Quiz successfully deleted.')
      deleteFail: I18n.t('flash.fail', 'Quiz deletion failed.')

    initialize: (options) ->
      @initializeChildViews()
      @observeModel()
      super

    initializeChildViews: ->
      @publishIconView = false
      @lockIconView = false
      @sisButtonView = false

      if @canManage()
        @publishIconView = new PublishIconView({
          model: @model,
          title: @model.get('title')
        })
        @lockIconView = new LockIconView({
          model: @model,
          unlockedText: I18n.t("%{name} is unlocked. Click to lock.", name: @model.get('title')),
          lockedText: I18n.t("%{name} is locked. Click to unlock", name: @model.get('title')),
          course_id: ENV.COURSE_ID,
          content_id: @model.get('id'),
          content_type: 'quiz'
        })
        if @model.postToSISEnabled() && @model.postToSIS() != null && @model.attributes.published
          @sisButtonView = new SisButtonView
            model: @model
            sisName: @model.postToSISName()
            dueDateRequired: @model.dueDateRequiredForAccount()
            maxNameLengthRequired: @model.maxNameLengthRequiredForAccount()

      @dateDueColumnView       = new DateDueColumnView(model: @model)
      @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

    afterRender: ->
      this.$el.toggleClass('quiz-loading-overrides', !!@model.get('loadingOverrides'))

    # make clicks follow through to url for entire row
    clickRow: (e) =>
      target = $(e.target)
      return if target.parents('.ig-admin').length > 0 or target.hasClass 'ig-title'

      row   = target.parents('li')
      title = row.find('.ig-title')
      @redirectTo title.attr('href') if title.length > 0

    redirectTo: (path) ->
      location.href = path

    migrateQuizEnabled: =>
      return ENV.FLAGS && ENV.FLAGS.migrate_quiz_enabled

    migrateQuiz: (e) =>
      e.preventDefault()
      courseId = ENV.context_asset_string.split('_')[1]
      quizId = @options.model.id
      url = "/api/v1/courses/#{courseId}/content_exports?export_type=quizzes2&quiz_id=#{quizId}"
      dfd = $.ajaxJSON url, 'POST'
      @$el.disableWhileLoading dfd
      $.when(dfd)
        .done (response, status, deferred) =>
          $.flashMessage I18n.t('Migration in progress')
        .fail =>
          $.flashError I18n.t('An error occurred while migrating.')

    canDelete: ->
      @model.get('permissions').delete

    onDelete: (e) =>
      e.preventDefault()
      if @canDelete()
        @delete() if confirm(@messages.confirm)

    # delete quiz item
    delete: ->
      @$el.hide()
      @model.destroy
        success : =>
          @$el.remove()
          $.flashMessage @messages.deleteSuccessful
        error : =>
          @$el.show()
          $.flashError @messages.deleteFail

    observeModel: ->
      @model.on('change:published', @updatePublishState)
      @model.on('change:loadingOverrides', @render)

    updatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    canManage: ->
      ENV.PERMISSIONS.manage

    toJSON: ->
      base = _.extend(@model.toJSON(), @options)
      base.quiz_menu_tools = ENV.quiz_menu_tools
      _.each base.quiz_menu_tools, (tool) =>
        tool.url = tool.base_url + "&quizzes[]=#{@model.get("id")}"

      base.cyoe = CyoeHelper.getItemData(base.assignment_id, base.quiz_type == 'assignment')
      base.return_to = encodeURIComponent window.location.pathname

      if @model.get("multiple_due_dates")
        base.selector  = @model.get("id")
        base.link_text = @messages.multipleDates
        base.link_href = @model.get("url")

      base.migrateQuizEnabled = @migrateQuizEnabled
      base.showAvailability = @model.multipleDueDates() or not @model.defaultDates().available()
      base.showDueDate = @model.multipleDueDates() or @model.singleSectionDueDate()

      base.is_locked = @model.get('is_master_course_child_content') &&
                       @model.get('restricted_by_master_course')
      base

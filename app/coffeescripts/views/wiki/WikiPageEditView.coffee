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
  'Backbone'
  'jsx/shared/rce/RichContentEditor'
  'jst/wiki/WikiPageEdit'
  '../ValidatedFormView'
  './WikiPageDeleteDialog'
  './WikiPageReloadView'
  'i18n!pages'
  '../editor/KeyboardShortcuts'
  'jquery.instructure_date_and_time'
], ($, Backbone, RichContentEditor, template, ValidatedFormView, WikiPageDeleteDialog, WikiPageReloadView, I18n, KeyboardShortcuts) ->

  RichContentEditor.preloadRemoteModule()

  class WikiPageEditView extends ValidatedFormView
    @mixin
      els:
        '[name="body"]': '$wikiPageBody'
        '.header-bar-outer-container': '$headerBarOuterContainer'
        '.page-changed-alert': '$pageChangedAlert'
        '.help_dialog': '$helpDialog'
        '#todo_date': '$studentTodoAt'
        '#todo_date_container': '$studentTodoAtContainer'

      events:
        'click a.switch_views': 'switchViews'
        'click .delete_page': 'deleteWikiPage'
        'click .form-actions .cancel': 'cancel'
        'click .form-actions .save_and_publish': 'saveAndPublish'
        'click #student_planner_checkbox': 'toggleStudentTodo'

    template: template
    className: "form-horizontal edit-form validated-form-view"
    dontRenableAfterSaveSuccess: true

    @optionProperty 'wiki_pages_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: (options = {}) ->
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}
      @on 'success', (args) => window.location.href = @model.get('html_url')
      @lockedItems = options.lockedItems || {}

    toJSON: ->
      json = super

      json.IS = IS =
        TEACHER_ROLE: false
        STUDENT_ROLE: false
        MEMBER_ROLE: false
        ANYONE_ROLE: false

      # rather than requiring the editing_roles to match a
      # string exactly, we check for individual editing roles
      editing_roles = json.editing_roles || ''
      editing_roles = editing_roles.split(',').map (s) -> s.trim()
      if editing_roles.includes('public')
        IS.ANYONE_ROLE = true
      else if editing_roles.includes('members')
        IS.MEMBER_ROLE = true
      else if editing_roles.includes('students')
        IS.STUDENT_ROLE = true
      else
        IS.TEACHER_ROLE = true

      json.CAN =
        PUBLISH: !!@WIKI_RIGHTS.publish_page
        # Annoying name conflict - PUBLISH means we're allowed to publish wiki
        # pages in general, PUBLISH_NOW means we can publish this page right
        # now (i.e. we can PUBLISH and this page is currently unpublished)
        PUBLISH_NOW: !!@WIKI_RIGHTS.publish_page && !@model.get('published')
        DELETE: !!@PAGE_RIGHTS.delete
        EDIT_TITLE: !!@PAGE_RIGHTS.update || json.new_record
        EDIT_ROLES: !!@WIKI_RIGHTS.manage
      json.SHOW =
        COURSE_ROLES: json.contextName == "courses"

      json.assignment = json.assignment?.toView()

      json.content_is_locked = @lockedItems.content

      json

    onUnload: (ev) =>
      # don't open the "are you sure" dialog unless we're still rendered in the page
      # so that, for example, our specs that don't clean up after themselves don't
      # fire this unintentionally
      if this && @checkUnsavedOnLeave && @hasUnsavedChanges() && document.body.contains(@el)
        warning = @unsavedWarning()
        (ev || window.event).returnValue = warning
        return warning


    # handles the toggling of the student todo date picker
    toggleStudentTodo: (e) =>
      @$studentTodoAtContainer.toggle()


    # After the page loads, ensure the that wiki sidebar gets initialized
    # correctly.
    # @api custom backbone override
    afterRender: ->
      super
      @$studentTodoAt.datetime_field()
      if !@toJSON().todo_date?
        @$studentTodoAtContainer.hide()

      RichContentEditor.initSidebar()
      RichContentEditor.loadNewEditor(@$wikiPageBody, { focus: true, manageParent: true })

      @checkUnsavedOnLeave = true
      $(window).on 'beforeunload', @onUnload

      unless @firstRender
        @firstRender = true
        $ -> $('[autofocus]:not(:focus)').eq(0).focus()

      @reloadPending = false
      @reloadView = new WikiPageReloadView
        el: @$pageChangedAlert
        model: @model
        interval: 60000
        reloadMessage: I18n.t 'reload_editing_page', 'This page has changed since you started editing it. *Reloading* will lose all of your changes.', wrapper: '<a class="reload" href="#">$1</a>'
        warning: true
      @reloadView.on 'changed', =>
        @$headerBarOuterContainer.addClass('page-changed')
        @reloadPending = true
      @reloadView.on 'reload', =>
        @render()
      @reloadView.pollForChanges()

      @$helpDialog.html((new KeyboardShortcuts()).render().$el)

    destroyEditor: ->
      RichContentEditor.destroyRCE(@$wikiPageBody)
      @$el.remove()

    switchViews: (event) ->
      event?.preventDefault()
      RichContentEditor.callOnRCE(@$wikiPageBody, 'toggle')
      # hide the clicked link, and show the other toggle link.
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(event.currentTarget).siblings('a').andSelf().toggle()

    # Validate they entered in a title.
    # @api ValidatedFormView override
    validateFormData: (data) ->
      errors = {}

      if data.title == ''
        errors['title'] = [
          {
            type: 'required'
            message: I18n.t('errors.require_title','You must enter a title')
          }
        ]

      if data.student_planner_checkbox == '1' && !data.student_todo_at?
        errors['student_todo_at'] = [
          {
            type: 'required'
            message: I18n.t('You must enter a date')
          }
        ]

      errors

    hasUnsavedChanges: ->
      hasEditor = RichContentEditor.callOnRCE(@$wikiPageBody, 'exists?')
      dirty =  hasEditor && RichContentEditor.callOnRCE(@$wikiPageBody, 'is_dirty')
      if not dirty and @toJSON().CAN.EDIT_TITLE
        dirty = (@model.get('title') || '') isnt (@getFormData().title || '')
      dirty

    unsavedWarning: ->
      I18n.t("warnings.unsaved_changes",
        "You have unsaved changes. Do you want to continue without saving these changes?")

    submit: (event) ->
      @checkUnsavedOnLeave = false
      if @reloadPending
        unless confirm(I18n.t 'warnings.overwrite_changes', 'You are about to overwrite other changes that have been made since you started editing.\n\nOverwrite these changes?')
          event?.preventDefault()
          return

      @reloadView?.stopPolling()
      super

    saveAndPublish: (event) ->
      @shouldPublish = true
      @submit(event)

    onSaveFail: (xhr) =>
      @shouldPublish = false
      super(xhr)

    getFormData: ->
      page_data = super

      assign_data = page_data.assignment

      if assign_data?.set_assignment is '1'
        assign_data.only_visible_to_overrides = true
        page_data.assignment = @model.get('assignment') or @model.createAssignment()
        page_data.assignment.set(assign_data)
      else
        page_data.assignment = @model.createAssignment(set_assignment: '0')
      page_data.set_assignment = page_data.assignment.get('set_assignment')
      page_data.student_planner_checkbox = planner_checkbox_is_checked = $("#student_planner_checkbox").is(":checked")
      if page_data.student_planner_checkbox
        page_data.todo_date = $("#todo_date").val()
      else
        page_data.todo_date = null

      page_data.published = true if @shouldPublish
      page_data

    cancel: (event) ->
      event?.preventDefault()
      if !@hasUnsavedChanges() || confirm(@unsavedWarning())
        @checkUnsavedOnLeave = false
        @trigger('cancel')

    deleteWikiPage: (event) ->
      event?.preventDefault()
      return unless @model.get('deletable')

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()

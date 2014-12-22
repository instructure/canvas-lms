define [
  'jquery'
  'underscore'
  'Backbone'
  'wikiSidebar'
  'jst/wiki/WikiPageEdit'
  'compiled/views/ValidatedFormView'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/wiki/WikiPageReloadView'
  'i18n!pages'
  'compiled/views/editor/KeyboardShortcuts'
  'compiled/tinymce'
  'tinymce.editor_box'
], ($, _, Backbone, wikiSidebar, template, ValidatedFormView, WikiPageDeleteDialog, WikiPageReloadView, I18n, KeyboardShortcuts) ->

  class WikiPageEditView extends ValidatedFormView
    @mixin
      els:
        '[name="body"]': '$wikiPageBody'
        '.header-bar-outer-container': '$headerBarOuterContainer'
        '.page-changed-alert': '$pageChangedAlert'
        '.help_dialog': '$helpDialog'

      events:
        'click a.switch_views': 'switchViews'
        'click .delete_page': 'deleteWikiPage'
        'click .form-actions .cancel': 'cancel'

    template: template
    className: "form-horizontal edit-form validated-form-view"
    dontRenableAfterSaveSuccess: true

    @optionProperty 'wiki_pages_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}
      @on 'success', (args) => window.location.href = @model.get('html_url')

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
      editing_roles = _.map(editing_roles.split(','), (s) -> s.trim())
      if _.contains(editing_roles, 'public')
        IS.ANYONE_ROLE = true
      else if _.contains(editing_roles, 'members')
        IS.MEMBER_ROLE = true
      else if _.contains(editing_roles, 'students')
        IS.STUDENT_ROLE = true
      else
        IS.TEACHER_ROLE = true

      json.CAN =
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == "courses"
        DELETE: !!@PAGE_RIGHTS.delete
        EDIT_TITLE: !!@PAGE_RIGHTS.update || json.new_record
        EDIT_ROLES: !!@WIKI_RIGHTS.manage
      json.SHOW =
        COURSE_ROLES: json.contextName == "courses"
      json

    onUnload: (ev) =>
      if this && @checkUnsavedOnLeave && @hasUnsavedChanges()
        warning = @unsavedWarning()
        (ev || window.event).returnValue = warning
        return warning

    # After the page loads, ensure the that wiki sidebar gets initialized
    # correctly.
    # @api custom backbone override
    afterRender: ->
      super
      @$wikiPageBody.editorBox()
      @initWikiSidebar()

      @checkUnsavedOnLeave = true
      view = this
      window.addEventListener 'beforeunload', @onUnload

      unless @firstRender
        @firstRender = true
        $ -> $('[autofocus]:not(:focus)').eq(0).focus()

      @reloadPending = false
      @reloadView = new WikiPageReloadView
        el: @$pageChangedAlert
        model: @model
        reloadMessage: I18n.t 'reload_editing_page', 'This page has changed since you started editing it. *Reloading* will lose all of your changes.', wrapper: '<a class="reload" href="#">$1</a>'
        warning: true
      @reloadView.on 'changed', =>
        @$headerBarOuterContainer.addClass('page-changed')
        @reloadPending = true
      @reloadView.on 'reload', =>
        @render()
      @reloadView.pollForChanges()

      @$helpDialog.html((new KeyboardShortcuts()).render().$el)


    # Initialize the wiki sidebar
    # @api private
    initWikiSidebar: ->
      unless wikiSidebar.inited
        $wikiPageBody = @$wikiPageBody
        $ ->
          wikiSidebar.init()
          $.scrollSidebar()
          wikiSidebar.attachToEditor($wikiPageBody).show()
      $ ->
        wikiSidebar.show()

    switchViews: (event) ->
      event?.preventDefault()
      @$wikiPageBody.editorBox('toggle')
      # hide the clicked link, and show the other toggle link.
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(event.currentTarget).siblings('a').andSelf().toggle()

    # Validate they entered in a title.
    # @api ValidatedFormView override
    validateFormData: (data) -> 
      errors = {}

      if data.title == ''
        errors["title"] = [
          {
            type: 'required'
            message: I18n.t("errors.require_title",'You must enter a title')
          }
        ]

      errors

    hasUnsavedChanges: ->
      dirty = @$wikiPageBody.editorBox('exists?') && @$wikiPageBody.editorBox('is_dirty')
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

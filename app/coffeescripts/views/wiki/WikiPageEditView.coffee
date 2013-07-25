define [
  'jquery'
  'underscore'
  'Backbone'
  'wikiSidebar'
  'jst/wiki/WikiPageEdit'
  'compiled/views/ValidatedFormView'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'i18n!pages'
  'compiled/tinymce'
  'tinymce.editor_box'
], ($, _, Backbone, wikiSidebar, template, ValidatedFormView, WikiPageDeleteDialog, I18n) ->

  class WikiPageEditView extends ValidatedFormView
    @mixin
      template: template
      className: "form-horizontal edit-form validated-form-view"
      dontRenableAfterSaveSuccess: true

      els:
        '[name="wiki_page[body]"]': '$wikiPageBody'

      events:
        'click a.switch_views': 'switchViews'
        'click .delete_page': 'deleteWikiPage'
        'click .form-actions .cancel': 'navigateToPageView'

    @optionProperty 'wiki_pages_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: ->
      super
      @on 'success', (args) => window.location.href = @model.get('html_url')

    toJSON: ->
      json = super
      json.WIKI_RIGHTS = @WIKI_RIGHTS
      json.PAGE_RIGHTS = @PAGE_RIGHTS
      json

    # After the page loads, ensure the that wiki sidebar gets initialized
    # correctly.
    # @api custom backbone override
    afterRender: ->
      super
      @$wikiPageBody.editorBox()
      @initWikiSidebar()

      unless @firstRender
        @firstRender = true
        $ -> $('[autofocus]:not(:focus)').eq(0).focus()

    # Initialize the wiki sidebar
    # @api private
    initWikiSidebar: ->
      unless wikiSidebar.inited
        $ ->
          wikiSidebar.init()
          $.scrollSidebar()
          wikiSidebar.attachToEditor(@$wikiPageBody).show()

    switchViews: (event) ->
      event?.preventDefault()
      @$wikiPageBody.editorBox('toggle')

    # Validate they entered in a title.
    # @api ValidatedFormView override
    validateFormData: (data) -> 
      errors = {}

      if data.wiki_page?.title == ''
        errors["wiki_page[title]"] = [
          {
            type: 'required'
            message: I18n.t("errors.require_title",'You must enter a title')
          }
        ]

      errors

    navigateToPageView: (event) ->
      event?.preventDefault()
      html_url = @model.get('html_url')
      window.location.href = html_url if html_url

    deleteWikiPage: (event) ->
      event?.preventDefault()

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()

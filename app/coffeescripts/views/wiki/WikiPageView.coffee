define [
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jst/wiki/WikiPage'
  'compiled/views/StickyHeaderMixin'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/wiki/WikiPageReloadView'
  'compiled/views/PublishButtonView'
  'i18n!pages'
], (_, Backbone, splitAssetString, template, StickyHeaderMixin, WikiPageDeleteDialog, WikiPageReloadView, PublishButtonView, I18n) ->

  class WikiPageView extends Backbone.View

    @mixin StickyHeaderMixin

    template: template

    els:
      '.publish-button': '$publishButton'
      '.header-bar-outer-container': '$headerBarOuterContainer'
      '.page-changed-alert': '$pageChangedAlert'

    events:
      'click .delete_page': 'deleteWikiPage'

    @optionProperty 'wiki_pages_path'
    @optionProperty 'wiki_page_edit_path'
    @optionProperty 'wiki_page_history_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: ->
      @model.on 'change', => @render()
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}

    render: ->
      # detach the publish button to preserve data/events
      @publishButtonView?.$el.detach()

      super

      # attach/re-attach the publish button
      unless @publishButtonView
        @publishButtonView = new PublishButtonView model: @model
        @model.view = @
      @publishButtonView.$el.appendTo(@$publishButton)
      @publishButtonView.render()

    afterRender: ->
      super
      @reloadView = new WikiPageReloadView
        el: @$pageChangedAlert
        model: @model
        reloadMessage: I18n.t 'reload_viewing_page', 'This page has changed since you started viewing it. *Reload*', wrapper: '<a class="reload" href="#">$1</a>'
      @reloadView.on 'changed', =>
        @$headerBarOuterContainer.addClass('page-changed')
      @reloadView.on 'reload', =>
        @render()
      @reloadView.pollForChanges()

    deleteWikiPage: (ev) ->
      ev?.preventDefault()
      return unless @model.get('deletable')

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()

    toJSON: ->
      json = super
      json.wiki_pages_path = @wiki_pages_path
      json.wiki_page_edit_path = @wiki_page_edit_path
      json.wiki_page_history_path = @wiki_page_history_path
      json.CAN =
        VIEW_PAGES: !!@WIKI_RIGHTS.read
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == 'courses'
        UPDATE_CONTENT: !!@PAGE_RIGHTS.update || !!@PAGE_RIGHTS.update_content
        DELETE: !!@PAGE_RIGHTS.delete
        READ_REVISIONS: !!@PAGE_RIGHTS.read_revisions
        ACCESS_GEAR_MENU: !!@PAGE_RIGHTS.delete || !!@PAGE_RIGHTS.read_revisions
      json.CAN.VIEW_TOOLBAR = json.CAN.VIEW_PAGES || json.CAN.PUBLISH || json.CAN.UPDATE_CONTENT || json.CAN.ACCESS_GEAR_MENU
      json

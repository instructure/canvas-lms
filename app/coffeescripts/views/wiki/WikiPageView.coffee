define [
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jst/wiki/WikiPage'
  'compiled/views/StickyHeaderMixin'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/PublishButtonView'
], (_, Backbone, splitAssetString, template, StickyHeaderMixin, WikiPageDeleteDialog, PublishButtonView) ->

  class WikiPageView extends Backbone.View

    @mixin StickyHeaderMixin

    template: template

    els:
      '.publish-button': '$publishButton'

    events:
      'click .delete_page': 'deleteWikiPage'

    @optionProperty 'wiki_pages_path'
    @optionProperty 'wiki_page_edit_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'

    initialize: ->
      @model.set('publishable', true)
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

    deleteWikiPage: (ev) ->
      ev?.preventDefault()

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()

    toJSON: ->
      json = super
      json.wiki_pages_path = @wiki_pages_path
      json.wiki_page_edit_path = @wiki_page_edit_path
      json.CAN =
        VIEW_PAGES: !!@WIKI_RIGHTS.read
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == 'courses'
        UPDATE_CONTENT: !!@PAGE_RIGHTS.update || !!@PAGE_RIGHTS.update_content
        DELETE: !!@PAGE_RIGHTS.delete
      json

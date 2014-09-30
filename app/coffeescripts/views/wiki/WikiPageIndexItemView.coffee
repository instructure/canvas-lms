define [
  'Backbone'
  'underscore'
  'compiled/views/wiki/WikiPageIndexEditDialog'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/PublishIconView'
  'jst/wiki/WikiPageIndexItem'
  'compiled/jquery/redirectClickTo'
], (Backbone, _, WikiPageIndexEditDialog, WikiPageDeleteDialog, PublishIconView, template) ->

  class WikiPageIndexItemView extends Backbone.View
    template: template
    tagName: 'tr'
    className: 'clickable'
    attributes:
      role: 'row'
    els:
      '.wiki-page-link': '$wikiPageLink'
      '.publish-cell': '$publishCell'
    events:
      'click a.al-trigger': 'settingsMenu'
      'click .edit-menu-item': 'editPage'
      'click .delete-menu-item': 'deletePage'
      'click .use-as-front-page-menu-item': 'useAsFrontPage'

    @optionProperty 'indexView'
    @optionProperty 'collection'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'contextName'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @model.set('unpublishable', true)
      @model.on 'change', => @render()

    toJSON: ->
      json = super
      json.CAN =
        MANAGE: !!@WIKI_RIGHTS.manage
        PUBLISH: !!@WIKI_RIGHTS.manage && @contextName == 'courses'

      json.wiki_page_menu_tools = ENV.wiki_page_menu_tools
      _.each json.wiki_page_menu_tools, (tool) =>
        tool.url = tool.base_url + "&pages[]=#{@model.get("page_id")}"
      json

    render: ->
      # detach the publish icon to preserve data/events
      @publishIconView?.$el.detach()

      super

      # attach/re-attach the publish icon
      unless @publishIconView
        @publishIconView = new PublishIconView model: @model
        @model.view = @
      @publishIconView.$el.appendTo(@$publishCell)
      @publishIconView.render()

    afterRender: ->
      @$el.find('td:first').redirectClickTo(@$wikiPageLink)

    settingsMenu: (ev) ->
      ev?.preventDefault()

    editPage: (ev) ->
      ev?.preventDefault()
      editDialog = new WikiPageIndexEditDialog
        model: @model
      editDialog.open()

      indexView = @indexView
      collection = @collection
      editDialog.on 'success', ->
        indexView.currentSortField = null
        indexView.renderSortHeaders()

        collection.fetch page: 'current'

    deletePage: (ev) ->
      ev?.preventDefault()
      return unless @model.get('deletable')

      deleteDialog = new WikiPageDeleteDialog
        model: @model
      deleteDialog.open()

    useAsFrontPage: (ev) ->
      ev?.preventDefault()
      return unless @model.get('published')

      @model.setFrontPage()

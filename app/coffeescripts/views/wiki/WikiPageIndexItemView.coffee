define [
  'Backbone'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/PublishIconView'
  'jst/wiki/WikiPageIndexItem'
  'compiled/jquery/redirectClickTo'
], (Backbone, WikiPageDeleteDialog, PublishIconView, template) ->

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
      'click .al-options .icon-edit': 'editPage'
      'click a.delete-menu-item': 'deletePage'
      'click a.set-front-page-menu-item': 'setAsFrontPage'
      'click a.remove-front-page-menu-item': 'removeAsFrontPage'

    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'contextName'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @model.set('publishable', true)
      @model.on 'change', => @render()

    toJSON: ->
      json = super
      json.CAN =
        MANAGE: !!@WIKI_RIGHTS.manage
        PUBLISH: !!@WIKI_RIGHTS.manage && @contextName == 'courses'
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
      @$el.redirectClickTo(@$wikiPageLink)

    settingsMenu: (ev) ->
      ev?.preventDefault()

    editPage: (ev) ->
      ev?.stopPropagation()

    deletePage: (ev) ->
      ev?.preventDefault()
      deleteDialog = new WikiPageDeleteDialog
        model: @model
      deleteDialog.open()

    setAsFrontPage: (ev) ->
      ev?.preventDefault()
      @model.setAsFrontPage()

    removeAsFrontPage: (ev) ->
      ev?.preventDefault()
      @model.removeAsFrontPage()

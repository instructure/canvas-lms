require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/collections/WikiPageRevisionsCollection'
  'compiled/views/wiki/WikiPageContentView'
  'compiled/views/wiki/WikiPageRevisionsView'
], ($, WikiPage, WikiPageRevisionsCollection, WikiPageContentView, WikiPageRevisionsView) ->

  $('body').addClass('show revisions')

  wikiPage = new WikiPage ENV.WIKI_PAGE, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string
  revisions = new WikiPageRevisionsCollection [],
    parentModel: wikiPage

  revisionsView = new WikiPageRevisionsView
    collection: revisions
    pages_path: ENV.WIKI_PAGES_PATH
  revisionsView.on 'selectionChanged', (newSelection) ->
    contentView.setModel(newSelection.model)
    if !newSelection.model.get('title') || newSelection.model.get('title') == ''
      contentView.$el.disableWhileLoading newSelection.model.fetch()
  revisionsView.$el.appendTo('#wiki_page_revisions')
  revisionsView.render()

  contentView = new WikiPageContentView
  contentView.$el.appendTo('#wiki_page_revisions')
  contentView.on 'render', ->
    revisionsView.reposition()
  contentView.render()

  revisionsView.collection.setParams per_page: 10
  revisionsView.collection.fetch()

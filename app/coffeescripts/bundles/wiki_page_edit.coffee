require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageEditView'
], ($, WikiPage, WikiPageEditView) ->

  $('body').addClass('edit')

  wikiPage = new WikiPage ENV.WIKI_PAGE, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string

  wikiPageEditView = new WikiPageEditView
    model: wikiPage
    wiki_pages_path: ENV.WIKI_PAGES_PATH
    WIKI_RIGHTS: ENV.WIKI_RIGHTS
    PAGE_RIGHTS: ENV.PAGE_RIGHTS
  $('#content').append(wikiPageEditView.$el)

  wikiPageEditView.on 'cancel', ->
    created_at = wikiPage.get('created_at')
    html_url = wikiPage.get('html_url')
    if !created_at || !html_url
      window.location.href = ENV.WIKI_PAGES_PATH if ENV.WIKI_PAGES_PATH
    else
      window.location.href = html_url

  wikiPageEditView.render()

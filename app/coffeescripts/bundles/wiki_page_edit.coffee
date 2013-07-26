require [
  'jquery'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageEditView'
], ($, WikiPage, WikiPageEditView) ->

  $('body').addClass('pages edit')

  wikiPage = new WikiPage ENV.WIKI_PAGE, contextAssetString: ENV.context_asset_string

  wikiPageEditView = new WikiPageEditView
    model: wikiPage
    wiki_pages_path: ENV.WIKI_PAGES_PATH
    WIKI_RIGHTS: ENV.WIKI_RIGHTS
    PAGE_RIGHTS: ENV.PAGE_RIGHTS
  $('#content').append(wikiPageEditView.$el)

  wikiPageEditView.on 'cancel', ->
    html_url = wikiPage.get('html_url')
    window.location.href = html_url if html_url

  wikiPageEditView.render()

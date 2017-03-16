import $ from 'jquery'
import WikiPage from 'compiled/models/WikiPage'
import WikiPageEditView from 'compiled/views/wiki/WikiPageEditView'

$('body').addClass('edit')

const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
  revision: ENV.WIKI_PAGE_REVISION,
  contextAssetString: ENV.context_asset_string,
  parse: true
})

const wikiPageEditView = new WikiPageEditView({
  model: wikiPage,
  wiki_pages_path: ENV.WIKI_PAGES_PATH,
  WIKI_RIGHTS: ENV.WIKI_RIGHTS,
  PAGE_RIGHTS: ENV.PAGE_RIGHTS
})
$('#content').append(wikiPageEditView.$el)

wikiPageEditView.on('cancel', () => {
  const created_at = wikiPage.get('created_at')
  const html_url = wikiPage.get('html_url')
  if (!created_at || !html_url) {
    if (ENV.WIKI_PAGES_PATH) { window.location.href = ENV.WIKI_PAGES_PATH }
  } else {
    window.location.href = html_url
  }
})

wikiPageEditView.render()

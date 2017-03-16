import $ from 'jquery'
import WikiPage from 'compiled/models/WikiPage'
import WikiPageRevisionsCollection from 'compiled/collections/WikiPageRevisionsCollection'
import WikiPageContentView from 'compiled/views/wiki/WikiPageContentView'
import WikiPageRevisionsView from 'compiled/views/wiki/WikiPageRevisionsView'
import I18n from 'i18n!pages'

$('body').addClass('show revisions')

const wikiPage = new WikiPage(ENV.WIKI_PAGE, {revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string})
const revisions = new WikiPageRevisionsCollection([], {parentModel: wikiPage})

const revisionsView = new WikiPageRevisionsView({
  collection: revisions,
  pages_path: ENV.WIKI_PAGES_PATH
})

const contentView = new WikiPageContentView()
contentView.$el.appendTo('#wiki_page_revisions')
contentView.on('render', () => revisionsView.reposition())
contentView.render()

revisionsView.on('selectionChanged', (newSelection) => {
  contentView.setModel(newSelection.model)
  if (!newSelection.model.get('title') || (newSelection.model.get('title') === '')) {
    return contentView.$el.disableWhileLoading(newSelection.model.fetch())
  }
})
revisionsView.$el.appendTo('#wiki_page_revisions')
revisionsView.render()

revisionsView.collection.setParams({per_page: 10})
revisionsView.collection.fetch()

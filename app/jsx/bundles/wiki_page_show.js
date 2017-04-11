import $ from 'jquery'
import WikiPage from 'compiled/models/WikiPage'
import WikiPageView from 'compiled/views/wiki/WikiPageView'
import MarkAsDone from 'compiled/util/markAsDone'
import LockManager from 'jsx/blueprint_courses/lockManager'
import 'compiled/jquery/ModuleSequenceFooter'

const lockManager = new LockManager()
lockManager.init({ itemType: 'wiki_page', page: 'show' })

$(() =>
  $('#content').on('click', '#mark-as-done-checkbox', function () {
    MarkAsDone.toggle(this)
  })
)

$('body').addClass('show')

const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
  revision: ENV.WIKI_PAGE_REVISION,
  contextAssetString: ENV.context_asset_string
})

const wikiPageView = new WikiPageView({
  el: '#wiki_page_show',
  model: wikiPage,
  modules_path: ENV.MODULES_PATH,
  wiki_pages_path: ENV.WIKI_PAGES_PATH,
  wiki_page_edit_path: ENV.WIKI_PAGE_EDIT_PATH,
  wiki_page_history_path: ENV.WIKI_PAGE_HISTORY_PATH,
  WIKI_RIGHTS: ENV.WIKI_RIGHTS,
  PAGE_RIGHTS: ENV.PAGE_RIGHTS,
  course_id: ENV.COURSE_ID,
  course_home: ENV.COURSE_HOME,
  course_title: ENV.COURSE_TITLE,
  display_show_all_pages: ENV.DISPLAY_SHOW_ALL_LINK
})

wikiPageView.render()

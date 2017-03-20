import $ from 'jquery'
import I18n from 'i18n!wiki_page_show'
import WikiPage from 'compiled/models/WikiPage'
import WikiPageView from 'compiled/views/wiki/WikiPageView'
import MarkAsDone from 'compiled/util/markAsDone'
import React from 'react'
import ReactDOM from 'react-dom'
import axios from 'axios'
import AnnouncementList from 'jsx/announcements/AnnouncementList'
import Spinner from 'instructure-ui/Spinner'
import 'compiled/jquery/ModuleSequenceFooter'

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

if (ENV.SHOW_ANNOUNCEMENTS) {
  const container = document.querySelector('#announcements_on_home_page')
  ReactDOM.render(<Spinner title={I18n.t('Loading Announcements')} size="small" />, container)

  const url = `/api/v1/announcements?context_codes[]=course_${ENV.COURSE_ID}&per_page=${ENV.ANNOUNCEMENT_LIMIT || 3}&page=1&start_date=1900-01-01&end_date=${new Date().toISOString()}&active_only=true&text_only=true`

  const presentAnnouncement = a => ({
    id: a.id,
    title: a.title,
    message: a.message,
    posted_at: a.delayed_post_at || a.posted_at,
    url: a.url
  })

  axios.get(url).then(response =>
    ReactDOM.render(<AnnouncementList announcements={response.data.map(presentAnnouncement)} />, container)
  )
}

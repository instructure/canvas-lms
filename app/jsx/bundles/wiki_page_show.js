require [
  'jquery'
  'i18n!wiki_page_show'
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageView'
  'compiled/util/markAsDone'
  'compiled/util/natcompare'
  'react'
  'react-dom'
  'axios'
  'jsx/announcements/AnnouncementList'
  'instructure-ui/Spinner'
  'compiled/jquery/ModuleSequenceFooter'
], ($, I18n, WikiPage, WikiPageView, MarkAsDone, natcompare, React, ReactDOM, axios, AnnouncementList, { default: Spinner }) ->

  renderReactComponent = (component, target, props) ->
    ReactDOM.render(
      React.createElement(component, props, null),
      document.querySelector(target)
    )

  $ ->
    $('#content').on('click', '#mark-as-done-checkbox', ->
      MarkAsDone.toggle(this)
    )

  $('body').addClass('show')

  wikiPage = new WikiPage ENV.WIKI_PAGE, revision: ENV.WIKI_PAGE_REVISION, contextAssetString: ENV.context_asset_string

  wikiPageView = new WikiPageView
    el: '#wiki_page_show'
    model: wikiPage
    modules_path: ENV.MODULES_PATH
    wiki_pages_path: ENV.WIKI_PAGES_PATH
    wiki_page_edit_path: ENV.WIKI_PAGE_EDIT_PATH
    wiki_page_history_path: ENV.WIKI_PAGE_HISTORY_PATH
    WIKI_RIGHTS: ENV.WIKI_RIGHTS
    PAGE_RIGHTS: ENV.PAGE_RIGHTS
    course_id: ENV.COURSE_ID
    course_home: ENV.COURSE_HOME
    course_title: ENV.COURSE_TITLE
    display_show_all_pages: ENV.DISPLAY_SHOW_ALL_LINK

  wikiPageView.render()

  if ENV.SHOW_ANNOUNCEMENTS
    renderReactComponent Spinner, '#announcements_on_home_page', {title: I18n.t('Loading Announcements'), size: 'small'}

    axios.get("/api/v1/announcements?context_codes[]=course_#{ENV.COURSE_ID}&per_page=#{ENV.ANNOUNCEMENT_LIMIT || 3}&page=1&start_date=1900-01-01&end_date=#{new Date().toISOString()}&active_only=true&text_only=true")
    .then (response) =>
      renderReactComponent AnnouncementList, '#announcements_on_home_page', announcements: response.data.map (a) ->
          id: a.id,
          title: a.title,
          message: a.message,
          posted_at: a.delayed_post_at || a.posted_at,
          url: a.url

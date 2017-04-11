import I18n from 'i18n!announcements_on_home_page'
import React from 'react'
import ReactDOM from 'react-dom'
import axios from 'axios'
import AnnouncementList from 'jsx/announcements/AnnouncementList'
import Spinner from 'instructure-ui/lib/components/Spinner'

if (ENV.SHOW_ANNOUNCEMENTS) {
  const container = document.querySelector('#announcements_on_home_page')
  ReactDOM.render(<Spinner title={I18n.t('Loading Announcements')} size="small" />, container)

  const url = `/api/v1/announcements?context_codes[]=course_${ENV.ANNOUNCEMENT_COURSE_ID}&per_page=${ENV.ANNOUNCEMENT_LIMIT || 3}&page=1&start_date=1900-01-01&end_date=${new Date().toISOString()}&active_only=true&text_only=true`

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

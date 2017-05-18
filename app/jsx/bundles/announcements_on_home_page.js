/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

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

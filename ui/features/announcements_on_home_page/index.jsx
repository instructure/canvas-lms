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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import axios from '@canvas/axios'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import AnnouncementRow from '@canvas/announcements/react/components/AnnouncementRow'
import ready from '@instructure/ready'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('announcements_on_home_page')

if (ENV.SHOW_ANNOUNCEMENTS) {
  ready(() => {
    const container = document.querySelector('#announcements_on_home_page')
    ReactDOM.render(
      <Spinner renderTitle={I18n.t('Loading Announcements')} size="small" />,
      container
    )

    const url = '/api/v1/announcements'

    const params = {
      context_codes: [`course_${ENV.COURSE.id}`],
      per_page: ENV.ANNOUNCEMENT_LIMIT || 3,
      page: '1',
      start_date: '1900-01-01',
      end_date: new Date().toISOString(),
      active_only: true,
      include: ['sections', 'sections_user_count'],
    }

    axios
      .get(url, {params})
      .then(response => {
        ReactDOM.render(
          <View display="block" margin="0 0 medium">
            <Heading
              level={['wiki', 'syllabus'].includes(ENV.COURSE.default_view) ? 'h1' : 'h2'}
              margin="0 0 small"
            >
              {I18n.t('Recent Announcements')}
            </Heading>
            {response.data.map(announcement => (
              <AnnouncementRow key={announcement.id} announcement={announcement} />
            ))}
          </View>,
          container
        )
      })
      .catch(error => {
        /* eslint-disable no-console */
        console.error('Error retrieving home page announcements')
        console.error(error)
        captureException(error)
        /* eslint-enable no-console */
      })
  })
}

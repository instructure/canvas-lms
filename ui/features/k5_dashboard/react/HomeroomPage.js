/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import K5DashboardCard from './K5DashboardCard'
import {createDashboardCards} from '@canvas/dashboard-card'
import {fetchLatestAnnouncement} from '@canvas/k5/react/utils'
import HomeroomAnnouncementsLayout from './HomeroomAnnouncementsLayout'

export const fetchHomeroomAnnouncements = cards =>
  Promise.all(
    cards
      .filter(c => c.isHomeroom)
      .map(course =>
        fetchLatestAnnouncement(course.id).then(announcement => {
          if (!announcement) {
            return {
              courseId: course.id,
              courseName: course.shortName,
              courseUrl: course.href,
              canEdit: course.canManage
            }
          }
          let attachment
          if (announcement.attachments[0]) {
            attachment = {
              display_name: announcement.attachments[0].display_name,
              url: announcement.attachments[0].url,
              filename: announcement.attachments[0].filename
            }
          }
          return {
            courseId: course.id,
            courseName: course.shortName,
            courseUrl: course.href,
            canEdit: announcement.permissions.update,
            announcement: {
              title: announcement.title,
              message: announcement.message,
              url: announcement.html_url,
              attachment
            }
          }
        })
      )
  ).then(announcements => announcements.filter(a => a))

export const HomeroomPage = props => {
  const {cards, requestTabChange, visible} = props
  const [dashboardCards] = useState(() =>
    createDashboardCards(
      cards.filter(c => !c.isHomeroom),
      K5DashboardCard,
      {
        headingLevel: 'h3',
        requestTabChange
      }
    )
  )
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])

  useEffect(() => {
    fetchHomeroomAnnouncements(cards).then(setHomeroomAnnouncements)
    // Cards are only ever loaded once on the page, so this only runs on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      {homeroomAnnouncements?.length > 0 && (
        <View as="section">
          <HomeroomAnnouncementsLayout homeroomAnnouncements={homeroomAnnouncements} />
        </View>
      )}
      {cards?.length > 0 && (
        <View as="section">
          <Heading level="h2" margin="medium 0 0 0">
            {I18n.t('My Subjects')}
          </Heading>
          {dashboardCards}
        </View>
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  cards: PropTypes.array.isRequired,
  requestTabChange: PropTypes.func.isRequired,
  visible: PropTypes.bool.isRequired
}

export default HomeroomPage

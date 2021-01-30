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

import K5DashboardCard from 'jsx/dashboard/cards/K5DashboardCard'
import {createDashboardCards} from 'jsx/bundles/dashboard_card'
import {fetchLatestAnnouncement} from 'jsx/dashboard/utils'

const HomeroomPage = ({cards, visible}) => {
  const [dashboardCards] = useState(() =>
    createDashboardCards(
      cards.filter(c => !c.isHomeroom),
      K5DashboardCard,
      {
        headingLevel: 'h3'
      }
    )
  )
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])

  useEffect(() => {
    Promise.all(
      cards
        .filter(c => c.isHomeroom)
        .map(course =>
          fetchLatestAnnouncement(course.id).then(announcement => {
            if (!announcement) {
              return null
            }
            return {
              id: announcement.id,
              title: announcement.title,
              message: announcement.message,
              url: announcement.html_url,
              courseName: course.shortName,
              courseUrl: course.href
            }
          })
        )
    )
      .then(announcements => announcements.filter(a => a))
      .then(setHomeroomAnnouncements)
  }, [cards])

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      {homeroomAnnouncements?.length > 0 && (
        <View as="section">{/* Homeroom content will go here */}</View>
      )}
      {cards?.length > 0 && (
        <View as="section">
          <Heading level="h2">{I18n.t('My Subjects')}</Heading>
          {dashboardCards}
        </View>
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  cards: PropTypes.array.isRequired,
  visible: PropTypes.bool.isRequired
}

export default HomeroomPage

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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'

import useImmediate from '@canvas/use-immediate-hook'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import K5DashboardCard, {CARD_SIZE_PX} from './K5DashboardCard'
import {createDashboardCards} from '@canvas/dashboard-card'
import {fetchLatestAnnouncement} from '@canvas/k5/react/utils'
import HomeroomAnnouncementsLayout from './HomeroomAnnouncementsLayout'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'

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

export const HomeroomPage = ({cards, cardsSettled, visible}) => {
  const [dashboardCards, setDashboardCards] = useState([])
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])
  const [announcementsLoading, setAnnouncementsLoading] = useState(true)

  useImmediate(
    () => {
      if (cards) {
        setDashboardCards(
          createDashboardCards(cards?.filter(c => !c.isHomeroom) || [], K5DashboardCard, {
            headingLevel: 'h3'
          })
        )
      }

      if (cardsSettled) {
        setAnnouncementsLoading(true)
        fetchHomeroomAnnouncements(cards)
          .then(setHomeroomAnnouncements)
          .catch(showFlashError(I18n.t('Failed to load announcements.')))
          .finally(() => setAnnouncementsLoading(false))
      }
    },
    [cards, cardsSettled],
    // Need to do deep comparison on cards to only re-trigger if they actually changed
    // (they shouldn't after they're set the first time)
    {deep: true}
  )

  const NUM_CARD_SKELETONS = ENV?.INITIAL_NUM_K5_CARDS || 5
  const skeletonCards = []
  for (let i = 0; i < NUM_CARD_SKELETONS; i++) {
    skeletonCards.push(
      <div
        className="ic-DashboardCard"
        key={`card-${i}`}
        style={{
          height: `${CARD_SIZE_PX}px`,
          minWidth: `${CARD_SIZE_PX}px`
        }}
      >
        <LoadingSkeleton screenReaderLabel={I18n.t('Loading Card')} height="100%" width="100%" />
      </div>
    )
  }

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      <View as="section">
        <HomeroomAnnouncementsLayout
          homeroomAnnouncements={homeroomAnnouncements}
          loading={announcementsLoading}
        />
      </View>
      {(!cards || cards.length > 0) && (
        <View as="section">
          <Heading level="h2" margin="medium 0 0 0">
            {I18n.t('My Subjects')}
          </Heading>
          {!cards ? (
            <div className="ic-DashboardCard__box">
              <div className="ic-DashboardCard__box__container">{skeletonCards}</div>
            </div>
          ) : (
            dashboardCards
          )}
        </View>
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  cards: PropTypes.array,
  cardsSettled: PropTypes.bool.isRequired,
  visible: PropTypes.bool.isRequired
}

export default HomeroomPage

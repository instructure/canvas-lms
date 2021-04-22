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
import {IconButton} from '@instructure/ui-buttons'
import {IconAddSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'

import K5DashboardCard, {CARD_SIZE_PX} from './K5DashboardCard'
import {createDashboardCards} from '@canvas/dashboard-card'
import {fetchLatestAnnouncement} from '@canvas/k5/react/utils'
import HomeroomAnnouncementsLayout from './HomeroomAnnouncementsLayout'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import {CreateCourseModal} from './CreateCourseModal'
import EmptyDashPandaUrl from '../images/empty-dashboard.svg'

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
  const {cards, visible, canCreateCourses} = props
  const [dashboardCards, setDashboardCards] = useState([])
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])
  const [announcementsLoading, setAnnouncementsLoading] = useState(true)
  const [courseModalOpen, setCourseModalOpen] = useState(false)

  useImmediate(
    () => {
      if (cards) {
        setDashboardCards(
          createDashboardCards(cards.filter(c => !c.isHomeroom) || [], K5DashboardCard, {
            headingLevel: 'h3'
          })
        )

        setAnnouncementsLoading(true)
        fetchHomeroomAnnouncements(cards)
          .then(setHomeroomAnnouncements)
          .catch(showFlashError(I18n.t('Failed to load announcements.')))
          .finally(() => setAnnouncementsLoading(false))
      }
    },
    [cards],
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
      <View as="section">
        <Flex alignItems="center" justifyItems="space-between" margin="small 0 0 0">
          <Flex.Item>
            <Heading level="h2">{I18n.t('My Subjects')}</Heading>
          </Flex.Item>
          {canCreateCourses && (
            <Flex.Item>
              <Tooltip renderTip={I18n.t('Start a new course')}>
                <IconButton
                  screenReaderLabel={I18n.t('Open new course modal')}
                  withBackground={false}
                  withBorder={false}
                  onClick={() => setCourseModalOpen(true)}
                >
                  <IconAddSolid />
                </IconButton>
              </Tooltip>
            </Flex.Item>
          )}
        </Flex>
        {!cards ? (
          <div className="ic-DashboardCard__box">
            <div className="ic-DashboardCard__box__container">{skeletonCards}</div>
          </div>
        ) : cards.length > 0 ? (
          dashboardCards
        ) : (
          <Flex direction="column" alignItems="center" margin="x-large large">
            <Img src={EmptyDashPandaUrl} margin="0 0 medium 0" data-testid="empty-dash-panda" />
            <Text>{I18n.t("You don't have any active courses yet.")}</Text>
          </Flex>
        )}
      </View>
      {courseModalOpen && (
        <CreateCourseModal isModalOpen={courseModalOpen} setModalOpen={setCourseModalOpen} />
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  cards: PropTypes.array,
  visible: PropTypes.bool.isRequired,
  canCreateCourses: PropTypes.bool.isRequired
}

export default HomeroomPage

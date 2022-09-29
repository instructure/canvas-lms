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
import {useScope as useI18nScope} from '@canvas/i18n'

import useImmediate from '@canvas/use-immediate-hook'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconAddSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'

import K5DashboardCard, {CARD_SIZE_PX} from './K5DashboardCard'
import {createDashboardCards} from '@canvas/dashboard-card'
import HomeroomAnnouncementsLayout from './HomeroomAnnouncementsLayout'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'
import {CreateCourseModal} from '@canvas/create-course-modal/react/CreateCourseModal'
import EmptyDashboardState from '@canvas/k5/react/EmptyDashboardState'

const I18n = useI18nScope('homeroom_page')

const HomeroomPage = ({
  cards,
  createPermission,
  restrictCourseCreation,
  homeroomAnnouncements,
  loadingAnnouncements,
  visible,
  loadingCards,
}) => {
  const [dashboardCards, setDashboardCards] = useState([])
  const [courseModalOpen, setCourseModalOpen] = useState(false)

  useImmediate(
    () => {
      if (cards) {
        setDashboardCards(
          createDashboardCards(cards.filter(c => !c.isHomeroom) || [], K5DashboardCard, {
            headingLevel: 'h3',
          })
        )
      }
    },
    [cards],
    // Need to do deep comparison on cards to only re-trigger if they actually changed
    {deep: true}
  )

  const skeletonCard = props => (
    <div
      {...props}
      className="ic-DashboardCard"
      style={{
        height: `${CARD_SIZE_PX}px`,
        minWidth: `${CARD_SIZE_PX}px`,
      }}
    >
      <LoadingSkeleton screenReaderLabel={I18n.t('Loading Card')} height="100%" width="100%" />
    </div>
  )

  const skeletonCardsContainer = skeletons => (
    <div className="ic-DashboardCard__box">
      <div className="ic-DashboardCard__box__container">{skeletons}</div>
    </div>
  )

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      <View as="section">
        <HomeroomAnnouncementsLayout
          homeroomAnnouncements={homeroomAnnouncements}
          loading={loadingAnnouncements}
        />
      </View>
      <View as="section">
        <Flex alignItems="center" justifyItems="space-between" margin="small 0 0 0">
          <Flex.Item>
            <Heading level="h2">{I18n.t('My Subjects')}</Heading>
          </Flex.Item>
          {createPermission && (
            <Flex.Item>
              <Tooltip renderTip={I18n.t('Start a new subject')}>
                <IconButton
                  data-testid="new-course-button"
                  screenReaderLabel={I18n.t('Open new subject modal')}
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
        <LoadingWrapper
          id="course-cards"
          isLoading={loadingCards}
          skeletonsNum={cards?.filter(c => !c.isHomeroom)?.length}
          defaultSkeletonsNum={ENV?.INITIAL_NUM_K5_CARDS}
          renderCustomSkeleton={skeletonCard}
          renderSkeletonsContainer={skeletonCardsContainer}
        >
          {cards?.length > 0 ? dashboardCards : <EmptyDashboardState />}
        </LoadingWrapper>
      </View>
      {courseModalOpen && (
        <CreateCourseModal
          isModalOpen={courseModalOpen}
          setModalOpen={setCourseModalOpen}
          permissions={createPermission}
          restrictToMCCAccount={restrictCourseCreation}
          isK5User={true}
        />
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  cards: PropTypes.array,
  createPermission: PropTypes.oneOf(['admin', 'teacher', 'student', 'no_enrollments']),
  restrictCourseCreation: PropTypes.bool.isRequired,
  homeroomAnnouncements: PropTypes.array.isRequired,
  loadingAnnouncements: PropTypes.bool.isRequired,
  visible: PropTypes.bool.isRequired,
  loadingCards: PropTypes.bool.isRequired,
}

export default HomeroomPage

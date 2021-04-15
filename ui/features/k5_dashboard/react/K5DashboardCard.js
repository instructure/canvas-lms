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

import React, {useContext, useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAnnouncementLine, IconBulletListLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'

import k5Theme from '@canvas/k5/react/k5-theme'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import {fetchLatestAnnouncement, FOCUS_TARGETS} from '@canvas/k5/react/utils'

import instFSOptimizedImageUrl from '@canvas/dashboard-card/util/instFSOptimizedImageUrl'

export const CARD_SIZE_PX = 300

export function DashboardCardHeaderHero({image, backgroundColor, onClick}) {
  return (
    <div
      style={{
        backgroundColor: !image && backgroundColor,
        backgroundImage:
          image && `url(${instFSOptimizedImageUrl(image, {x: CARD_SIZE_PX, y: CARD_SIZE_PX / 2})})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center center',
        backgroundRepeat: 'no-repeat',
        height: `${CARD_SIZE_PX / 2}px`,
        cursor: 'pointer'
      }}
      onClick={onClick}
      aria-hidden="true"
      data-testid="k5-dashboard-card-hero"
    />
  )
}

DashboardCardHeaderHero.displayName = 'DashboardCardHeaderHero'
DashboardCardHeaderHero.propTypes = {
  backgroundColor: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
  image: PropTypes.string
}

export const LatestAnnouncementLink = ({color, loading, title, html_url}) =>
  loading ? (
    <Flex alignItems="start" margin="xx-small small xx-small small">
      <Flex.Item shouldGrow shouldShrink>
        <LoadingSkeleton
          screenReaderLabel={I18n.t('Loading latest announcement link')}
          width="100%"
          height="1.5em"
        />
      </Flex.Item>
    </Flex>
  ) : title && html_url ? (
    <Link
      href={html_url}
      display="block"
      isWithinText={false}
      margin="xx-small small xx-small small"
    >
      <Flex alignItems="start">
        <Flex.Item margin="0 small 0 0">
          <IconAnnouncementLine style={{color}} size="x-small" />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink>
          <AccessibleContent alt={I18n.t('New announcement: %{title}', {title})}>
            <Text color="primary">
              <TruncateText maxLines={2}>{title}</TruncateText>
            </Text>
          </AccessibleContent>
        </Flex.Item>
      </Flex>
    </Link>
  ) : null

LatestAnnouncementLink.displayName = 'LatestAnnouncementLink'
LatestAnnouncementLink.propTypes = {
  color: PropTypes.string.isRequired,
  loading: PropTypes.bool.isRequired,
  html_url: PropTypes.string,
  title: PropTypes.string
}

export const AssignmentLinks = ({
  color,
  courseName,
  switchToMissingItems,
  switchToToday,
  numDueToday = 0,
  numMissing = 0,
  numSubmittedToday = 0,
  loading
}) => {
  const noneDueMessage =
    numSubmittedToday > 0 ? (
      <AccessibleContent
        alt={I18n.t('Nothing else due today for course %{courseName}', {courseName})}
      >
        {I18n.t('Nothing else due')}
      </AccessibleContent>
    ) : (
      <AccessibleContent alt={I18n.t('Nothing due today for course %{courseName}', {courseName})}>
        {I18n.t('Nothing due today')}
      </AccessibleContent>
    )
  const content = (
    <>
      {numDueToday > 0 ? (
        <Flex.Item>
          <Link
            href={`/?focusTarget=${FOCUS_TARGETS.TODAY}#schedule`}
            onClick={e => {
              e.preventDefault()
              switchToToday()
            }}
            display="block"
            isWithinText={false}
            theme={{
              color: k5Theme.variables.colors.textDarkest,
              hoverColor: k5Theme.variables.colors.textDarkest
            }}
          >
            <AccessibleContent
              alt={I18n.t('View %{due} items due today for course %{courseName}', {
                due: numDueToday,
                courseName
              })}
            >
              <Text>{I18n.t('%{due} due today', {due: numDueToday})}</Text>
            </AccessibleContent>
          </Link>
        </Flex.Item>
      ) : (
        <Text color="secondary" fontStyle="italic">
          {noneDueMessage}
        </Text>
      )}
      {numMissing > 0 && (
        <>
          <Flex.Item padding="0 xx-small">
            <Text color="secondary">|</Text>
          </Flex.Item>
          <Flex.Item>
            <Link
              href={`/?focusTarget=${FOCUS_TARGETS.MISSING_ITEMS}#schedule`}
              onClick={e => {
                e.preventDefault()
                switchToMissingItems()
              }}
              display="block"
              isWithinText={false}
              theme={{
                color: k5Theme.variables.colors.textDanger,
                hoverColor: k5Theme.variables.colors.textDanger
              }}
            >
              <AccessibleContent
                alt={I18n.t('View %{missing} missing items for course %{courseName}', {
                  missing: numMissing,
                  courseName
                })}
              >
                <Text color="danger">{I18n.t('%{missing} missing', {missing: numMissing})}</Text>
              </AccessibleContent>
            </Link>
          </Flex.Item>
        </>
      )}
    </>
  )
  return (
    <Flex alignItems="center" margin="small small xx-small small">
      {loading ? (
        <Flex.Item shouldGrow shouldShrink>
          <LoadingSkeleton
            screenReaderLabel={I18n.t('Loading missing assignments link')}
            width="100%"
            height="1.5em"
          />
        </Flex.Item>
      ) : (
        <>
          <Flex.Item margin="0 small xxx-small 0">
            <IconBulletListLine style={{color}} size="x-small" />
          </Flex.Item>
          {content}
        </>
      )}
    </Flex>
  )
}

AssignmentLinks.displayName = 'AssignmentLinks'
AssignmentLinks.propTypes = {
  color: PropTypes.string.isRequired,
  courseName: PropTypes.string.isRequired,
  switchToMissingItems: PropTypes.func.isRequired,
  switchToToday: PropTypes.func.isRequired,
  numDueToday: PropTypes.number,
  numMissing: PropTypes.number,
  numSubmittedToday: PropTypes.number,
  loading: PropTypes.bool.isRequired
}

const K5DashboardCard = ({
  href,
  id,
  originalName,
  backgroundColor = '#394B58',
  connectDragSource = c => c,
  connectDropTarget = c => c,
  headingLevel = 'h3',
  image,
  isDragging = false
}) => {
  const [latestAnnouncement, setLatestAnnouncement] = useState(null)
  const [loadingAnnouncement, setLoadingAnnouncement] = useState(false)
  useEffect(() => {
    setLoadingAnnouncement(true)
    fetchLatestAnnouncement(id)
      .then(setLatestAnnouncement)
      .catch(
        showFlashError(I18n.t('Failed to load announcement for %{originalName}.', {originalName}))
      )
      .finally(() => setLoadingAnnouncement(false))
  }, [id, originalName])

  const k5Context = useContext(K5DashboardContext)
  const assignmentsDueToday =
    (k5Context?.assignmentsDueToday && k5Context.assignmentsDueToday[id]) || 0
  const assignmentsMissing =
    (k5Context?.assignmentsMissing && k5Context.assignmentsMissing[id]) || 0
  const assignmentsCompletedForToday =
    (k5Context?.assignmentsCompletedForToday && k5Context.assignmentsCompletedForToday[id]) || 0
  const loadingOpportunities = k5Context?.loadingOpportunities || false
  const isStudent = k5Context?.isStudent || false
  const switchToMissingItems = k5Context?.switchToMissingItems
  const switchToToday = k5Context?.switchToToday

  const handleHeaderClick = e => {
    if (e) {
      e.preventDefault()
    }
    window.location = href
  }

  // The transform: translate3d(0,0,0) below is required to do a Chrome bug with react-dnd drag
  // previews for components containing elements that use overflow: hidden.
  // See https://github.com/react-dnd/react-dnd/issues/832
  const dashboardCard = (
    <div
      className="ic-DashboardCard"
      style={{
        display: 'inline-flex',
        flexDirection: 'column',
        opacity: isDragging ? 0 : 1,
        transform: 'translate3d(0,0,0)',
        minHeight: `${CARD_SIZE_PX}px`,
        minWidth: `${CARD_SIZE_PX}px`
      }}
      aria-label={originalName}
      data-testid="k5-dashboard-card"
    >
      <DashboardCardHeaderHero
        image={image}
        backgroundColor={backgroundColor}
        onClick={handleHeaderClick}
      />
      <View as="div" minHeight={`${CARD_SIZE_PX / 2}px`}>
        <Heading
          as={headingLevel}
          level="h4"
          margin="small"
          color="inherit"
          border="bottom"
          theme={{borderColor: backgroundColor, borderPadding: '0.5rem'}}
        >
          <Link
            href={href}
            display="block"
            isWithinText={false}
            theme={{
              color: k5Theme.variables.colors.textDarkest,
              hoverColor: k5Theme.variables.colors.textDarkest,
              fontWeight: 700
            }}
          >
            <div
              style={{
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                textTransform: 'uppercase',
                whiteSpace: 'nowrap'
              }}
              title={originalName}
            >
              {originalName}
            </div>
          </Link>
        </Heading>
        {isStudent && (
          <AssignmentLinks
            color={backgroundColor}
            courseName={originalName}
            numDueToday={assignmentsDueToday}
            numMissing={assignmentsMissing}
            numSubmittedToday={assignmentsCompletedForToday}
            loading={loadingOpportunities}
            switchToMissingItems={switchToMissingItems}
            switchToToday={switchToToday}
          />
        )}
        <LatestAnnouncementLink
          color={backgroundColor}
          loading={loadingAnnouncement}
          {...latestAnnouncement}
        />
      </View>
    </div>
  )

  return connectDragSource(connectDropTarget(dashboardCard))
}

K5DashboardCard.displayName = 'K5DashboardCard'
K5DashboardCard.propTypes = {
  href: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  originalName: PropTypes.string.isRequired,
  backgroundColor: PropTypes.string,
  connectDragSource: PropTypes.func,
  connectDropTarget: PropTypes.func,
  headingLevel: PropTypes.string,
  image: PropTypes.string,
  isDragging: PropTypes.bool
}

export default K5DashboardCard

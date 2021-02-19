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

import k5Theme from 'jsx/dashboard/k5-theme'
import K5DashboardContext from 'jsx/dashboard/K5DashboardContext'
import {fetchLatestAnnouncement} from 'jsx/dashboard/utils'
import {TAB_IDS} from '../DashboardTabs'

import instFSOptimizedImageUrl from 'jsx/shared/helpers/instFSOptimizedImageUrl'

export const CARD_WIDTH_PX = 300

export function DashboardCardHeaderHero({image, backgroundColor, onClick}) {
  return (
    <div
      style={{
        backgroundColor: !image && backgroundColor,
        backgroundImage:
          image &&
          `url(${instFSOptimizedImageUrl(image, {x: CARD_WIDTH_PX, y: CARD_WIDTH_PX / 2})})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center center',
        backgroundRepeat: 'no-repeat',
        height: `${CARD_WIDTH_PX / 2}px`,
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

const LatestAnnouncementLink = ({color, title, html_url}) => (
  <Link href={html_url} display="block" isWithinText={false} margin="small">
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
)

LatestAnnouncementLink.displayName = 'LatestAnnouncementLink'
LatestAnnouncementLink.propTypes = {
  color: PropTypes.string.isRequired,
  html_url: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
}

const AssignmentLinks = ({color, requestTabChange, numDueToday = 0, numMissing = 0}) => {
  const content = (
    <>
      {numDueToday > 0 ? (
        <Flex.Item>
          <Link
            href="/#schedule"
            onClick={e => {
              e.preventDefault()
              requestTabChange(TAB_IDS.SCHEDULE)
            }}
            display="block"
            isWithinText={false}
            theme={{
              color: k5Theme.variables.colors.textDarkest,
              hoverColor: k5Theme.variables.colors.textDarkest
            }}
          >
            <Text>{I18n.t('%{due} due today', {due: numDueToday})}</Text>
          </Link>
        </Flex.Item>
      ) : (
        <Text color="secondary" fontStyle="italic">
          {I18n.t('Nothing due today')}
        </Text>
      )}
      {numMissing > 0 && (
        <>
          <Flex.Item padding="0 xx-small">
            <Text color="secondary">|</Text>
          </Flex.Item>
          <Flex.Item>
            <Link
              href="/#schedule"
              onClick={e => {
                e.preventDefault()
                requestTabChange(TAB_IDS.SCHEDULE)
              }}
              display="block"
              isWithinText={false}
              theme={{
                color: k5Theme.variables.colors.textDanger,
                hoverColor: k5Theme.variables.colors.textDanger
              }}
            >
              <Text color="danger">{I18n.t('%{missing} missing', {missing: numMissing})}</Text>
            </Link>
          </Flex.Item>
        </>
      )}
    </>
  )
  return (
    <Flex alignItems="center" margin="small">
      <Flex.Item margin="0 small xxx-small 0">
        <IconBulletListLine style={{color}} size="x-small" />
      </Flex.Item>
      {content}
    </Flex>
  )
}

AssignmentLinks.displayName = 'AssignmentLinks'
AssignmentLinks.propTypes = {
  color: PropTypes.string.isRequired,
  requestTabChange: PropTypes.func.isRequired,
  numDueToday: PropTypes.number,
  numMissing: PropTypes.number
}

const K5DashboardCard = ({
  href,
  id,
  originalName,
  requestTabChange,
  backgroundColor = '#394B58',
  connectDragSource = c => c,
  connectDropTarget = c => c,
  headingLevel = 'h3',
  image,
  isDragging = false
}) => {
  const [latestAnnouncement, setLatestAnnouncement] = useState(null)
  useEffect(() => {
    fetchLatestAnnouncement(id).then(setLatestAnnouncement)
  }, [id])

  const k5Context = useContext(K5DashboardContext)
  const assignmentsDueToday =
    (k5Context?.assignmentsDueToday && k5Context.assignmentsDueToday[id]) || 0
  const assignmentsMissing =
    (k5Context?.assignmentsMissing && k5Context.assignmentsMissing[id]) || 0
  const isStudent = k5Context?.isStudent || false
  const responsiveWidth = k5Context?.responsiveSize === 'large' ? CARD_WIDTH_PX : '100%'

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
      style={{opacity: isDragging ? 0 : 1, transform: 'translate3d(0,0,0)', width: responsiveWidth}}
      aria-label={originalName}
      data-testid="k5-dashboard-card"
    >
      <DashboardCardHeaderHero
        image={image}
        backgroundColor={backgroundColor}
        onClick={handleHeaderClick}
      />
      <View as="div" height={`${CARD_WIDTH_PX / 2}px`}>
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
            numDueToday={assignmentsDueToday}
            numMissing={assignmentsMissing}
            requestTabChange={requestTabChange}
          />
        )}
        {latestAnnouncement && (
          <LatestAnnouncementLink color={backgroundColor} {...latestAnnouncement} />
        )}
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
  requestTabChange: PropTypes.func.isRequired,
  backgroundColor: PropTypes.string,
  connectDragSource: PropTypes.func,
  connectDropTarget: PropTypes.func,
  headingLevel: PropTypes.string,
  image: PropTypes.string,
  isDragging: PropTypes.bool
}

export default K5DashboardCard

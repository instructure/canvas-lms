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
import {IconAnnouncementLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import k5Theme from 'jsx/dashboard/k5-theme'
import K5DashboardContext from 'jsx/dashboard/K5DashboardContext'
import {fetchLatestAnnouncement} from 'jsx/dashboard/utils'

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

LatestAnnouncementLink.propTypes = {
  color: PropTypes.string.isRequired,
  html_url: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
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
  useEffect(() => {
    fetchLatestAnnouncement(id).then(setLatestAnnouncement)
  }, [id])

  const k5Context = useContext(K5DashboardContext)
  const responsiveWidth = k5Context.responsiveSize === 'large' ? CARD_WIDTH_PX : '100%'

  const handleHeaderClick = e => {
    if (e) {
      e.preventDefault()
    }
    window.location = href
  }

  const dashboardCard = (
    <div
      className="ic-DashboardCard"
      style={{opacity: isDragging ? 0 : 1, width: responsiveWidth}}
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
              style={{overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}}
              title={originalName}
            >
              {originalName}
            </div>
          </Link>
        </Heading>
        {latestAnnouncement && (
          <LatestAnnouncementLink color={backgroundColor} {...latestAnnouncement} />
        )}
      </View>
    </div>
  )

  return connectDragSource(connectDropTarget(dashboardCard))
}

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

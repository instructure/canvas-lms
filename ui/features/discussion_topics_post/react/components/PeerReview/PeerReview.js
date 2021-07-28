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

import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconPeerGradedLine, IconPeerReviewLine} from '@instructure/ui-icons'

export const PeerReview = props => {
  let icon, message
  if (props.workflowState === 'completed') {
    icon = <IconPeerGradedLine title="Review Complete" />
    message = (
      <Text>
        {I18n.t('You have completed a peer review for %{name}', {name: props.revieweeName})}
      </Text>
    )
  } else {
    icon = <IconPeerReviewLine title="Review Assigned" />
    message = (
      <Text>
        {props.dueAtDisplayText
          ? I18n.t('Peer review for %{name} Due: %{dueAtText}', {
              name: props.revieweeName,
              dueAtText: props.dueAtDisplayText
            })
          : I18n.t('Peer review for %{name}', {name: props.revieweeName})}
        <Link href={props.reviewLinkUrl} isWithinText={false} margin="0 0 0 xx-small">
          <Text weight="bold">{I18n.t('Review Now')}</Text>
        </Link>
      </Text>
    )
  }

  return (
    <Flex>
      <Flex.Item margin="0 xx-small 0 0">{icon}</Flex.Item>
      <Flex.Item>{message}</Flex.Item>
    </Flex>
  )
}

PeerReview.propTypes = {
  dueAtDisplayText: PropTypes.string,
  revieweeName: PropTypes.string.isRequired,
  reviewLinkUrl: PropTypes.string,
  workflowState: PropTypes.string.isRequired
}

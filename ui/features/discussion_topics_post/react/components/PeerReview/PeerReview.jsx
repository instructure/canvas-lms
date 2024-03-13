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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'
import DateHelper from '@canvas/datetime/dateHelper'

import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconPeerGradedLine, IconPeerReviewLine} from '@instructure/ui-icons'
import {Responsive} from '@instructure/ui-responsive/lib/Responsive'

const I18n = useI18nScope('discussion_posts')

export const PeerReview = props => {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          textCompleted: I18n.t('Completed'),
          textNotCompleted: props.dueAtDisplayText
            ? I18n.t('Peer review due %{dueAtText}', {
                name: props.revieweeName,
                dueAtText: DateHelper.formatDateForDisplay(
                  props.dueAtDisplayText,
                  'short',
                  ENV.TIMEZONE
                ),
              })
            : I18n.t('Peer review due', {name: props.revieweeName}),
          textSize: 'x-small',
        },
        desktop: {
          textCompleted: I18n.t('You have completed a peer review for %{name}', {
            name: props.revieweeName,
          }),
          textNotCompleted: props.dueAtDisplayText
            ? I18n.t('Peer review for %{name} Due: %{dueAtText}', {
                name: props.revieweeName,
                dueAtText: DateHelper.formatDatetimeForDiscussions(props.dueAtDisplayText),
              })
            : I18n.t('Peer review for %{name}', {name: props.revieweeName}),
          textSize: 'medium',
        },
      }}
      render={(responsiveProps, matches) => {
        let icon, message
        if (props.workflowState === 'completed') {
          icon = <IconPeerGradedLine />
          message = <Text size={responsiveProps.textSize}>{responsiveProps.textCompleted}</Text>
        } else if (matches.includes('mobile')) {
          icon = <IconPeerReviewLine />
          message = (
            <Text weight="bold" size="x-small">
              {responsiveProps.textNotCompleted}
            </Text>
          )

          return (
            <Flex>
              <span className="discussions-peer-review">
                <Link href={props.reviewLinkUrl} isWithinText={false} margin="0 xx-small 0 x-small">
                  <Flex.Item>{icon}</Flex.Item>
                  <Flex.Item margin="0 0 0 x-small">{message}</Flex.Item>
                </Link>
              </span>
            </Flex>
          )
        } else {
          icon = <IconPeerReviewLine />
          message = (
            <Text>
              {responsiveProps.textNotCompleted}
              <Link href={props.reviewLinkUrl} isWithinText={false} margin="0 xx-small 0 x-small">
                <Text weight="bold" size={responsiveProps.textSize}>
                  {I18n.t('Review Now')}
                </Text>
              </Link>
            </Text>
          )
        }

        return (
          <Flex>
            <Flex.Item margin="0 xx-small 0 x-small">{icon}</Flex.Item>
            <Flex.Item>
              <span className="discussions-peer-review">{message}</span>
            </Flex.Item>
          </Flex>
        )
      }}
    />
  )
}

PeerReview.propTypes = {
  dueAtDisplayText: PropTypes.string,
  revieweeName: PropTypes.string.isRequired,
  reviewLinkUrl: PropTypes.string,
  workflowState: PropTypes.string.isRequired,
}

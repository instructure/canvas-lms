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

import I18n from 'i18n!discussions_posts'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'

export const ReplyInfo = props => {
  const getFullText = () => {
    return props.unreadCount > 0
      ? I18n.t(
          {
            one: '%{replyCount} reply, %{unreadCount} unread',
            other: '%{replyCount} replies, %{unreadCount} unread'
          },
          {
            count: props.replyCount,
            replyCount: props.replyCount,
            unreadCount: props.unreadCount
          }
        )
      : I18n.t(
          {one: '%{replyCount} reply', other: '%{replyCount} replies'},
          {count: props.replyCount, replyCount: props.replyCount}
        )
  }

  const getCondensedText = () => {
    return props.unreadCount > 0
      ? I18n.t(
          {
            one: '%{replyCount} reply (%{unreadCount})',
            other: '%{replyCount} replies (%{unreadCount})'
          },
          {
            count: props.replyCount,
            replyCount: props.replyCount,
            unreadCount: props.unreadCount
          }
        )
      : I18n.t(
          {one: '%{replyCount} reply', other: '%{replyCount} replies'},
          {count: props.replyCount, replyCount: props.replyCount}
        )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          displayText: getCondensedText(),
          screenReaderLabel: getFullText()
        },
        desktop: {
          displayText: getFullText(),
          screenReaderLabel: getFullText()
        }
      }}
      render={responsiveProps => (
        <AccessibleContent alt={responsiveProps.screenReaderLabel}>
          <div data-testid="replies-counter">{responsiveProps.displayText}</div>
        </AccessibleContent>
      )}
    />
  )
}

ReplyInfo.propTypes = {
  /**
   * The total number of replies
   */
  replyCount: PropTypes.number,
  /**
   * The number of unread replies
   */
  unreadCount: PropTypes.number
}

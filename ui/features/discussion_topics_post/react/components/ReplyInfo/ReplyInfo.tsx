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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {getFullReplyText} from '../../utils/helpers'

const I18n = createI18nScope('discussions_posts')

// @ts-expect-error TS7006 (typescriptify)
export const ReplyInfo = props => {
  const fullText = getFullReplyText(props.replyCount, props.unreadCount)

  const getCondensedText = () => {
    return props.unreadCount > 0
      ? I18n.t(
          {
            one: '%{replyCount} Reply (%{unreadCount})',
            other: '%{replyCount} Replies (%{unreadCount})',
          },
          {
            count: props.replyCount,
            replyCount: props.replyCount,
            unreadCount: props.unreadCount,
          },
        )
      : I18n.t(
          {one: '%{replyCount} Reply', other: '%{replyCount} Replies'},
          {count: props.replyCount, replyCount: props.replyCount},
        )
  }

  return (
    <Responsive
      match="media"
      // @ts-expect-error TS2769 (typescriptify)
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          displayText: getCondensedText(),
          screenReaderLabel: fullText,
        },
        desktop: {
          displayText: fullText,
          screenReaderLabel: fullText,
        },
      }}
      render={responsiveProps => (
        <AccessibleContent
          alt={
            props.showHide
              ? // @ts-expect-error TS18049 (typescriptify)
                I18n.t('Hide %{details}', {details: responsiveProps.screenReaderLabel})
              : // @ts-expect-error TS18049 (typescriptify)
                responsiveProps.screenReaderLabel
          }
        >
          <div data-testid="replies-counter">
            {props.showHide
              ? // @ts-expect-error TS18049 (typescriptify)
                I18n.t(`Hide %{details}`, {details: responsiveProps.displayText})
              : // @ts-expect-error TS18049 (typescriptify)
                responsiveProps.displayText}
          </div>
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
  unreadCount: PropTypes.number,
  /**
   * If the component should display "Hide"
   */
  showHide: PropTypes.bool,
}

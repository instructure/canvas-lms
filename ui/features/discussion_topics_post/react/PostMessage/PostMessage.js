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

import {Avatar} from '@instructure/ui-avatar'
import {Badge} from '@instructure/ui-badge'
import {Byline} from '@instructure/ui-byline'
import {Pill} from '@instructure/ui-pill'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export function PostMessage({...props}) {
  return (
    <Byline
      title={
        <>
          <Text weight="bold">{props.authorName}</Text>
          <View padding="0 small">
            <Text color="secondary">{props.timingDisplay}</Text>
          </View>
          {props.pillText && <Pill data-testid="post-pill">{props.pillText}</Pill>}
        </>
      }
      description={
        <>
          {props.message}
          <View display="block" margin="small none none none">
            {props.children}
          </View>
        </>
      }
      alignContent="top"
      margin="0 0 medium 0"
    >
      {props.isUnread && (
        <div
          style={{
            float: 'left',
            'margin-left': '-24px',
            'margin-top': '13px'
          }}
        >
          <Badge
            type="notification"
            placement="start center"
            standalone
            formatOutput={() => <ScreenReaderContent>{I18n.t('Unread post')}</ScreenReaderContent>}
          />
        </div>
      )}
      <Avatar name={props.authorName} src={props.avatarUrl} margin="0 0 0 0" />
    </Byline>
  )
}

PostMessage.propTypes = {
  /**
   * Display name for the author of the message
   */
  authorName: PropTypes.string.isRequired,
  /**
   * Source url for the user's avatar
   */
  avatarUrl: PropTypes.string,
  /**
   * Children to be directly rendered below the PostMessage
   */
  children: PropTypes.node,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string.isRequired,
  /**
   * Display text for the post's message
   */
  message: PropTypes.string.isRequired,
  /**
   * Display text for the message pill.
   * Providing this prop will result in the pill being displayed.
   */
  pillText: PropTypes.string,
  /**
   * Determines if the unread badge should be displayed
   */
  isUnread: PropTypes.bool
}

export default PostMessage

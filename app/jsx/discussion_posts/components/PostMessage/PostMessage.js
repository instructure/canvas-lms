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
      description={props.message}
      alignContent="top"
    >
      {props.isUnread ? (
        <Badge
          type="notification"
          placement="start center"
          formatOutput={() => <ScreenReaderContent>{I18n.t('Unread post')}</ScreenReaderContent>}
        >
          <Avatar name={props.authorName} src={props.avatarUrl} margin="0 0 0 small" />
        </Badge>
      ) : (
        <Avatar name={props.authorName} src={props.avatarUrl} margin="0 0 0 small" />
      )}
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

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
import {DiscussionEdit} from '../DiscussionEdit/DiscussionEdit'

export function PostMessage({...props}) {
  return (
    <Byline
      title={
        <>
          <Text weight="bold">{props.authorName}</Text>
          <View padding="0 small">
            <Text color="secondary">{props.timingDisplay}</Text>
            <Text color="secondary">
              {!!props.lastReplyAtDisplayText &&
                I18n.t(', last reply %{lastReplyAtDisplayText}', {
                  lastReplyAtDisplayText: props.lastReplyAtDisplayText
                })}
            </Text>
          </View>
          {props.pillText && <Pill data-testid="post-pill">{props.pillText}</Pill>}
        </>
      }
      description={
        <>
          {props.title && (
            <View as="div" margin="medium none">
              <Text size="x-large">{props.title}</Text>
            </View>
          )}
          {props.isEditing ? (
            <View display="inline-block" margin="small none none none" width="100%">
              <DiscussionEdit
                onCancel={props.onCancel}
                value={props.message}
                onSubmit={props.onSave}
              />
            </View>
          ) : (
            <>
              <div dangerouslySetInnerHTML={{__html: props.message}} />
              <View display="block" margin="small none none none">
                {props.children}
              </View>
            </>
          )}
        </>
      }
      alignContent="top"
      margin="0 0 medium 0"
    >
      {props.isUnread && (
        <div
          style={{
            float: 'left',
            marginLeft: '-24px',
            marginTop: '13px'
          }}
          data-testid="is-unread"
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
   * Last Reply Date if there are discussion replies
   */
  lastReplyAtDisplayText: PropTypes.string,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string.isRequired,
  /**
   * Display text for the post's title. Only pass this in if it's a DiscussionTopic
   */
  title: PropTypes.string,
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
  isUnread: PropTypes.bool,
  /**
   * Determines if the editor should be displayed
   */
  isEditing: PropTypes.bool,
  /**
   * Callback for when Editor Save button is pressed
   */
  onSave: PropTypes.func,
  /**
   * Callback for when Editor Cancel button is pressed
   */
  onCancel: PropTypes.func
}

export default PostMessage

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

import PropTypes from 'prop-types'
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {PostToolbar} from '../PostToolbar/PostToolbar'

export function PostMessage({...props}) {
  const addDebug = true
  return (
    <View display="block" padding="small">
      <Flex withVisualDebug={addDebug}>
        <Flex.Item shouldGrow={false}>
          {/* TODO: add avatar display VICE-934 */}
          AVATAR
        </Flex.Item>
        <Flex.Item shouldGrow>
          <Flex direction="column" withVisualDebug={addDebug}>
            <Flex.Item>
              <Flex width="100%" justifyItems="space-between">
                <Flex.Item>
                  {/* TODO author info VICE-934 */}
                  AUTHOR INFO
                </Flex.Item>
                <PostToolbar
                  onReadAll={props.onReadAll}
                  onDelete={props.onDelete}
                  onToggleComments={props.onToggleComments}
                  commentsEnabled={props.commentsEnabled}
                  onSend={props.onSend}
                  onCopy={props.onCopy}
                  onEdit={props.onEdit}
                  onTogglePublish={props.onTogglePublish}
                  isPublished={props.isPublished}
                  onToggleSubscription={props.onToggleSubscription}
                  isSubscribed={props.isSubscribed}
                />
              </Flex>
            </Flex.Item>
            <Flex.Item>
              {/* TODO message VICE-932 */}
              MESSAGE
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

PostMessage.propTypes = {
  /**
   * Behavior for marking the thread as read
   */
  onReadAll: PropTypes.func.isRequired,
  /**
   * Behavior for deleting the discussion post.
   * Providing this function will result in the menu option being rendered.
   */
  onDelete: PropTypes.func,
  /**
   * Behavior for toggling the ability to comment on the post.
   * Providing this function will result in the menu option being rendered.
   */
  onToggleComments: PropTypes.func,
  /**
   * Indicates whether comments have been enabled or not.
   * Which toggling menu option is rendered is dependent on this prop.
   */
  commentsEnabled: PropTypes.bool,
  /**
   * Behavior for sending to a recipient.
   * Providing this function will result in the menu option being rendered.
   */
  onSend: PropTypes.func,
  /**
   * Behavior for copying a post.
   * Providing this function will result in the menu option being rendered.
   */
  onCopy: PropTypes.func,
  /**
   * Behavior for editing a post.
   * Providing this function will result in the button being rendered.
   */
  onEdit: PropTypes.func,
  /**
   * Behavior for toggling the published state of the post.
   * Providing this function will result in the button being rendered.
   */
  onTogglePublish: PropTypes.func,
  /**
   * Indicates whether the post is published or unpublished.
   * Which state the publish button is in is dependent on this prop.
   */
  isPublished: PropTypes.bool,
  /**
   * Behavior for toggling the subscription state of the post.
   * Providing this function will result in the button being rendered.
   */
  onToggleSubscription: PropTypes.func,
  /**
   * Indicates whether the user has subscribed to the post.
   * Which state the subscription button is in is dependent on this prop.
   */
  isSubscribed: PropTypes.bool
}

export default PostMessage

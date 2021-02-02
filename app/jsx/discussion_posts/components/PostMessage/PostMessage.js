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
import {Menu} from '@instructure/ui-menu'
import {
  IconMoreLine,
  IconMarkAsReadLine,
  IconTrashLine,
  IconLockLine,
  IconUnlockLine,
  IconUserLine,
  IconDuplicateLine,
  IconEditLine
} from '@instructure/ui-icons'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!conversations_2'
import {PublishButton} from './PublishButton'

export function PostMessage({...props}) {
  return (
    <View display="block" padding="small" background="secondary">
      <Flex width="100%" justifyItems="end">
        {props.onTogglePublish && (
          <PublishButton
            key={props.publishState}
            initialState={props.publishState}
            onClick={props.onTogglePublish}
          />
        )}
        {props.onEdit && (
          <Button renderIcon={IconEditLine} onClick={props.onEdit} margin="0 x-small 0 xxx-small">
            {I18n.t('Edit')}
          </Button>
        )}
        {renderMenu(props)}
      </Flex>
    </View>
  )
}

const renderMenu = props => {
  return (
    <Menu
      trigger={
        <IconButton
          screenReaderLabel={I18n.t('Manage Discussion')}
          renderIcon={IconMoreLine}
          data-testid="discussion-post-menu-trigger"
        />
      }
    >
      {getMenuConfigs(props).map(config => renderMenuItem({...config}))}
    </Menu>
  )
}

const getMenuConfigs = props => {
  const options = [
    {
      key: 'read-all',
      icon: <IconMarkAsReadLine />,
      labelCallback: () => I18n.t('Mark All as Read'),
      selectionCallback: props.onReadAll
    }
  ]
  if (props.onDelete) {
    options.push({
      key: 'delete',
      icon: <IconTrashLine />,
      labelCallback: () => I18n.t('Delete'),
      selectionCallback: props.onDelete
    })
  }
  if (props.onToggleComments && props.commentsEnabled) {
    options.push({
      key: 'toggle-comments',
      icon: <IconLockLine />,
      labelCallback: () => I18n.t('Close for Comments'),
      selectionCallback: props.onToggleComments
    })
  } else if (props.onToggleComments && !props.commentsEnabled) {
    options.push({
      key: 'toggle-comments',
      icon: <IconUnlockLine />,
      labelCallback: () => I18n.t('Open for Comments'),
      selectionCallback: props.onToggleComments
    })
  }
  if (props.onSend) {
    options.push({
      key: 'send',
      icon: <IconUserLine />,
      labelCallback: () => I18n.t('Send To...'),
      selectionCallback: props.onSend
    })
  }
  if (props.onCopy) {
    options.push({
      key: 'copy',
      icon: <IconDuplicateLine />,
      labelCallback: () => I18n.t('Copy To...'),
      selectionCallback: props.onCopy
    })
  }
  return options
}

const renderMenuItem = ({selectionCallback, icon, labelCallback, key}) => {
  return (
    <Menu.Item key={key} onSelect={selectionCallback}>
      <Flex>
        <Flex.Item>{icon}</Flex.Item>
        <Flex.Item padding="0 0 0 xx-small">
          <Text>{labelCallback.call()}</Text>
        </Flex.Item>
      </Flex>
    </Menu.Item>
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
   * Indicates whether the post is published, publishing, or unpublished.
   * Which state the publish button is in is dependent on this prop.
   */
  publishState: PropTypes.oneOf(['published', 'publishing', 'unpublished', 'unpublishing'])
}

export default PostMessage

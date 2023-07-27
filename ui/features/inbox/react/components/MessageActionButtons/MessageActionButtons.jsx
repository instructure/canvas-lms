/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import React, {useContext} from 'react'
import {ConversationContext} from '../../../util/constants'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconAddFolderLine,
  IconCollectionSaveLine,
  IconComposeLine,
  IconMoreLine,
  IconRemoveFromCollectionLine,
  IconReplyAll2Line,
  IconReplyLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('conversations_2')

const Settings = props => (
  <Menu
    placement="bottom"
    trigger={
      <Tooltip renderTip={I18n.t('More options')} placement="top">
        <Button
          renderIcon={IconMoreLine}
          disabled={props.settingsDisabled}
          data-testid="settings"
          aria-label={I18n.t('More options')}
        />
      </Tooltip>
    }
    disabled={props.settingsDisabled}
  >
    {props.shouldRenderMarkAsRead && (
      <Menu.Item value="MarkAsRead" onSelect={() => props.markAsRead()} data-testid="mark-as-read">
        {props.hasMultipleSelectedMessages ? I18n.t('Mark all as read') : I18n.t('Mark as read')}
      </Menu.Item>
    )}
    {props.shouldRenderMarkAsUnread && (
      <Menu.Item
        value="MarkAsUnread"
        onSelect={() => props.markAsUnread()}
        data-testid="mark-as-unread"
      >
        {props.hasMultipleSelectedMessages
          ? I18n.t('Mark all as unread')
          : I18n.t('Mark as unread')}
      </Menu.Item>
    )}
    <Menu.Item value="Forward" onSelect={() => props.forward()}>
      {I18n.t('Forward')}
    </Menu.Item>
    {props.star && (
      <Menu.Item value="Star" onSelect={() => props.star()}>
        {I18n.t('Star')}
      </Menu.Item>
    )}
    {props.unstar && (
      <Menu.Item value="Unstar" onSelect={() => props.unstar()}>
        {I18n.t('Unstar')}
      </Menu.Item>
    )}
  </Menu>
)

const ActionButton = props => (
  <Tooltip renderTip={props.tip} placement="top">
    <Button
      renderIcon={props.icon}
      onClick={props.onClick}
      margin="0 x-small 0 0"
      interaction={props.disabled ? 'disabled' : 'enabled'}
      data-testid={props.testid}
      aria-label={props.ariaLabel}
    />
  </Tooltip>
)

export const MessageActionButtons = props => {
  const {isSubmissionCommentsType} = useContext(ConversationContext)
  if (isSubmissionCommentsType) {
    return (
      <ActionButton
        tip={I18n.t('Reply')}
        icon={IconReplyLine}
        onClick={props.reply}
        testid="reply"
        disabled={props.replyDisabled}
        ariaLabel={I18n.t('Reply')}
      />
    )
  }

  return (
    <Flex>
      <Flex.Item shouldGrow={true}>
        <View padding="0 medium 0 0">
          <ActionButton
            tip={I18n.t('Compose a new message')}
            icon={IconComposeLine}
            onClick={props.compose}
            testid="compose"
            ariaLabel={I18n.t('Compose a new message')}
          />
          {ENV?.react_inbox_labels && (
            <ActionButton
              tip={I18n.t('Manage labels')}
              icon={IconAddFolderLine}
              onClick={props.manageLabels}
              disabled={props.manageLabels === null}
              testid="manage-labels"
              ariaLabel={I18n.t('Manage labels')}
            />
          )}
        </View>
      </Flex.Item>
      <Flex.Item>
        <ActionButton
          tip={I18n.t('Reply')}
          icon={IconReplyLine}
          onClick={props.reply}
          disabled={props.replyDisabled}
          testid="reply"
          ariaLabel={I18n.t('Reply')}
        />
        <ActionButton
          tip={I18n.t('Reply all')}
          icon={IconReplyAll2Line}
          onClick={props.replyAll}
          disabled={props.replyDisabled}
          testid="reply-all"
          ariaLabel={I18n.t('Reply all')}
        />
        <ActionButton
          tip={props.unarchive ? I18n.t('Unarchive') : I18n.t('Archive')}
          icon={props.unarchive ? IconRemoveFromCollectionLine : IconCollectionSaveLine}
          onClick={props.unarchive ? props.unarchive : props.archive}
          disabled={props.archiveDisabled}
          testid={props.unarchive ? 'unarchive' : 'archive'}
          ariaLabel={props.unarchive ? I18n.t('Unarchive') : I18n.t('Archive')}
        />
        <ActionButton
          tip={I18n.t('Delete')}
          icon={IconTrashLine}
          onClick={props.delete}
          disabled={props.deleteDisabled}
          testid="delete"
          ariaLabel={I18n.t('Delete')}
        />
        <Settings {...props} />
      </Flex.Item>
    </Flex>
  )
}

MessageActionButtons.propTypes = {
  replyDisabled: PropTypes.bool,
  archiveDisabled: PropTypes.bool,
  deleteDisabled: PropTypes.bool,
  settingsDisabled: PropTypes.bool,
  compose: PropTypes.func.isRequired,
  manageLabels: PropTypes.func,
  reply: PropTypes.func.isRequired,
  replyAll: PropTypes.func.isRequired,
  archive: PropTypes.func,
  unarchive: PropTypes.func,
  delete: PropTypes.func.isRequired,
  markAsUnread: PropTypes.func,
  markAsRead: PropTypes.func,
  forward: PropTypes.func.isRequired,
  star: PropTypes.func,
  unstar: PropTypes.func,
  shouldRenderMarkAsRead: PropTypes.bool,
  shouldRenderMarkAsUnread: PropTypes.bool,
  hasMultipleSelectedMessages: PropTypes.bool,
}

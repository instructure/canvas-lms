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
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {
  IconCollectionSaveLine,
  IconComposeLine,
  IconMiniArrowDownLine,
  IconRemoveFromCollectionLine,
  IconReplyAll2Line,
  IconReplyLine,
  IconSettingsLine,
  IconTrashLine
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Tooltip} from '@instructure/ui-tooltip'
import I18n from 'i18n!conversations_2'

const Settings = props => (
  <Menu
    placement="bottom"
    trigger={
      <Tooltip renderTip={I18n.t('More options')} placement="top">
        <Button
          renderIcon={IconSettingsLine}
          disabled={props.settingsDisabled}
          data-testid="settings"
        >
          <IconMiniArrowDownLine />
        </Button>
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
    <Menu.Item value="Star" onSelect={() => props.star()}>
      {I18n.t('Star')}
    </Menu.Item>
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
    />
  </Tooltip>
)

export const MessageActionButtons = props => {
  if (props.isSubmissionComment) {
    return (
      <ActionButton
        tip={I18n.t('Reply')}
        icon={IconReplyLine}
        onClick={props.reply}
        disabled={props.replyDisabled}
        testid="reply"
      />
    )
  }

  return (
    <>
      <ActionButton
        tip={I18n.t('Compose a new message')}
        icon={IconComposeLine}
        onClick={props.compose}
        testid="compose"
      />
      <ActionButton
        tip={I18n.t('Reply')}
        icon={IconReplyLine}
        onClick={props.reply}
        disabled={props.replyDisabled}
        testid="reply"
      />
      <ActionButton
        tip={I18n.t('Reply all')}
        icon={IconReplyAll2Line}
        onClick={props.replyAll}
        disabled={props.replyDisabled}
        testid="reply-all"
      />
      <ActionButton
        tip={props.unarchive ? I18n.t('Unarchive') : I18n.t('Archive')}
        icon={props.unarchive ? IconRemoveFromCollectionLine : IconCollectionSaveLine}
        onClick={props.unarchive ? props.unarchive : props.archive}
        disabled={props.archiveDisabled}
        testid={props.unarchive ? 'unarchive' : 'archive'}
      />
      <ActionButton
        tip={I18n.t('Delete')}
        icon={IconTrashLine}
        onClick={props.delete}
        disabled={props.deleteDisabled}
        testid="delete"
      />
      <Settings {...props} />
    </>
  )
}

MessageActionButtons.propTypes = {
  isSubmissionComment: PropTypes.bool,
  replyDisabled: PropTypes.bool,
  archiveDisabled: PropTypes.bool,
  deleteDisabled: PropTypes.bool,
  settingsDisabled: PropTypes.bool,
  compose: PropTypes.func.isRequired,
  reply: PropTypes.func.isRequired,
  replyAll: PropTypes.func.isRequired,
  archive: PropTypes.func,
  unarchive: PropTypes.func,
  delete: PropTypes.func.isRequired,
  markAsUnread: PropTypes.func,
  markAsRead: PropTypes.func,
  forward: PropTypes.func.isRequired,
  star: PropTypes.func.isRequired,
  shouldRenderMarkAsRead: PropTypes.bool,
  shouldRenderMarkAsUnread: PropTypes.bool,
  hasMultipleSelectedMessages: PropTypes.bool
}

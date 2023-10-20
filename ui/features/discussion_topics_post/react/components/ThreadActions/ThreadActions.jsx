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
import React, {useMemo} from 'react'

import {Menu} from '@instructure/ui-menu'
import {
  IconMoreLine,
  IconNextUnreadLine,
  IconDiscussionLine,
  IconEditLine,
  IconTrashLine,
  IconSpeedGraderLine,
  IconMarkAsReadSolid,
  IconMarkAsReadLine,
  IconWarningBorderlessSolid,
  IconReplyAll2Line,
  IconCommentLine,
} from '@instructure/ui-icons'

import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('discussion_posts')

// Reason: <Menu> in v6 of InstUI requires a ref to bind too or errors
// are produced by the menu causing the page to scroll all over the place
export const ThreadActions = props => {
  const menuItems = useMemo(() => {
    return getMenuConfigs({
      onMarkAllAsRead: props.onMarkAllAsRead,
      onMarkAllAsUnread: props.onMarkAllAsUnread,
      isUnread: props.isUnread,
      onToggleUnread: props.onToggleUnread,
      goToTopic: props.goToTopic,
      goToParent: props.goToParent,
      goToQuotedReply: props.goToQuotedReply,
      onEdit: props.onEdit,
      onDelete: props.onDelete,
      onQuoteReply: props.onQuoteReply,
      onOpenInSpeedGrader: props.onOpenInSpeedGrader,
      onMarkThreadAsRead: props.onMarkThreadAsRead,
      onReport: props.onReport,
      isReported: props.isReported,
    }).map(config => renderMenuItem({...config}, props.id))
  }, [props])

  return (
    <Flex justifyItems="end">
      <Flex.Item>
        {!props.isSearch && (
          <Menu
            placement="bottom"
            key={`threadActionMenu-${props.id}`}
            trigger={
              <IconButton
                size="medium"
                screenReaderLabel={I18n.t('Manage Discussion by %{author}', {
                  author: props.authorName,
                })}
                renderIcon={IconMoreLine}
                withBackground={false}
                withBorder={false}
                data-testid="thread-actions-menu"
              />
            }
            ref={props.moreOptionsButtonRef}
          >
            {menuItems}
          </Menu>
        )}
      </Flex.Item>
    </Flex>
  )
}

const getMenuConfigs = props => {
  const options = []
  if (props.onMarkAllAsRead) {
    options.push({
      key: 'markAllAsRead',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark All as Read'),
      selectionCallback: props.onMarkAllAsRead,
    })
  }
  if (props.onMarkAllAsUnread) {
    options.push({
      key: 'markAllAsUnRead',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark All as Unread'),
      selectionCallback: props.onMarkAllAsUnread,
    })
  }
  if (props.isUnread) {
    options.push({
      key: 'markAsRead',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark as Read'),
      selectionCallback: props.onToggleUnread,
    })
  } else {
    options.push({
      key: 'markAsUnread',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark as Unread'),
      selectionCallback: props.onToggleUnread,
    })
  }
  if (props.onMarkThreadAsRead) {
    options.push({
      key: 'markThreadAsRead',
      icon: <IconMarkAsReadLine />,
      label: I18n.t('Mark Thread as Read'),
      selectionCallback: () => {
        props.onMarkThreadAsRead(true)
      },
    })
  }
  if (props.onMarkThreadAsRead) {
    options.push({
      key: 'markThreadAsUnRead',
      icon: <IconMarkAsReadSolid />,
      label: I18n.t('Mark Thread as Unread'),
      selectionCallback: () => {
        props.onMarkThreadAsRead(false)
      },
    })
  }
  if (props.goToTopic) {
    options.push({
      key: 'toTopic',
      icon: <IconDiscussionLine />,
      label: I18n.t('Go To Topic'),
      selectionCallback: props.goToTopic,
    })
  }
  if (props.goToParent) {
    options.push({
      key: 'toParent',
      icon: <IconDiscussionLine />,
      label: I18n.t('Go To Parent'),
      selectionCallback: props.goToParent,
    })
  }
  if (props.goToQuotedReply) {
    options.push({
      key: 'toQuotedReply',
      icon: <IconReplyAll2Line />,
      label: I18n.t('Go To Quoted Reply'),
      selectionCallback: props.goToQuotedReply,
    })
  }
  if (props.onEdit) {
    options.push({
      key: 'edit',
      icon: <IconEditLine />,
      label: I18n.t('Edit'),
      selectionCallback: props.onEdit,
    })
  }
  if (props.onQuoteReply) {
    options.push({
      key: 'quote',
      icon: <IconCommentLine />,
      label: I18n.t('Quote Reply'),
      selectionCallback: props.onQuoteReply,
    })
  }
  if (props.onDelete) {
    options.push({
      key: 'delete',
      icon: <IconTrashLine />,
      label: I18n.t('Delete'),
      selectionCallback: props.onDelete,
    })
  }
  if (props.onOpenInSpeedGrader) {
    options.push({
      key: 'inSpeedGrader',
      icon: <IconSpeedGraderLine />,
      label: I18n.t('Open in SpeedGrader'),
      selectionCallback: props.onOpenInSpeedGrader,
    })
  }
  if (props.onReport) {
    options.push({
      key: 'separator',
      separator: true,
    })
    options.push({
      key: 'report',
      icon: <IconWarningBorderlessSolid />,
      label: props.isReported ? I18n.t('Reported') : I18n.t('Report'),
      selectionCallback: props.onReport,
      disabled: props.isReported,
    })
  }
  return options
}

const renderMenuItem = (
  {selectionCallback, icon, label, key, separator = false, disabled = false, color},
  id
) => {
  return separator ? (
    <Menu.Separator key={key} />
  ) : (
    <Menu.Item
      key={`${key}-${id}`}
      onSelect={() => {
        selectionCallback(key)
      }}
      data-testid={key}
      disabled={disabled}
    >
      <span className={`discussion-thread-menuitem-${key}`}>
        <Text color={color}>
          <Flex>
            <Flex.Item>{icon}</Flex.Item>
            <Flex.Item padding="0 0 0 xx-small">
              <Text>{label}</Text>
            </Flex.Item>
          </Flex>
        </Text>
      </span>
    </Menu.Item>
  )
}

ThreadActions.propTypes = {
  authorName: PropTypes.string,
  id: PropTypes.string.isRequired,
  onMarkAllAsUnread: PropTypes.func,
  onMarkAllAsRead: PropTypes.func,
  onMarkThreadAsRead: PropTypes.func,
  onToggleUnread: PropTypes.func.isRequired,
  isUnread: PropTypes.bool,
  goToTopic: PropTypes.func,
  goToParent: PropTypes.func,
  goToQuotedReply: PropTypes.func,
  onEdit: PropTypes.func,
  onQuoteReply: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onReport: PropTypes.func,
  isReported: PropTypes.bool,
  isSearch: PropTypes.bool,
  moreOptionsButtonRef: PropTypes.any,
}

ThreadActions.defaultProps = {
  isUnread: false,
  isSearch: false,
  isReported: false,
}

export default ThreadActions

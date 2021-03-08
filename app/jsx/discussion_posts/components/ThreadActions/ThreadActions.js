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

import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React from 'react'

import {Menu} from '@instructure/ui-menu'
import {
  IconMoreLine,
  IconNextUnreadLine,
  IconDiscussionLine,
  IconEditLine,
  IconTrashLine,
  IconSpeedGraderLine
} from '@instructure/ui-icons'

import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

export function ThreadActions({...props}) {
  return (
    <Menu
      placement="bottom"
      trigger={
        <IconButton
          size="small"
          screenReaderLabel={I18n.t('Manage Discussion')}
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          data-testid="thread-actions-menu"
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
      key: 'markAsUnread',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark All as Read'),
      selectionCallback: props.markAsUnread
    }
  ]
  if (props.goToTopic) {
    options.push({
      key: 'toTopic',
      icon: <IconDiscussionLine />,
      label: I18n.t('Go To Topic'),
      selectionCallback: props.goToTopic
    })
  }
  if (props.goToParent) {
    options.push({
      key: 'toParent',
      icon: <IconDiscussionLine />,
      label: I18n.t('Go To Parent'),
      selectionCallback: props.goToParent
    })
  }
  if (props.onEdit) {
    options.push({
      key: 'edit',
      icon: <IconEditLine />,
      label: I18n.t('Edit'),
      selectionCallback: props.onEdit
    })
  }
  if (props.onDelete) {
    options.push({
      key: 'delete',
      icon: <IconTrashLine />,
      label: I18n.t('Delete'),
      selectionCallback: props.onDelete
    })
  }
  if (props.openInSpeedGrader) {
    options.push({
      key: 'inSpeedGrader',
      icon: <IconSpeedGraderLine />,
      label: I18n.t('Open in SpeedGrader'),
      selectionCallback: props.openInSpeedGrader
    })
  }
  return options
}

const renderMenuItem = ({selectionCallback, icon, label, key}) => (
  <Menu.Item key={key} onSelect={selectionCallback} data-testid={key}>
    <Flex>
      <Flex.Item>{icon}</Flex.Item>
      <Flex.Item padding="0 0 0 xx-small">
        <Text>{label}</Text>
      </Flex.Item>
    </Flex>
  </Menu.Item>
)

ThreadActions.propTypes = {
  markAsUnread: PropTypes.func.isRequired,
  goToTopic: PropTypes.func,
  goToParent: PropTypes.func,
  onEdit: PropTypes.func,
  onDelete: PropTypes.func,
  openInSpeedGrader: PropTypes.func
}

export default ThreadActions

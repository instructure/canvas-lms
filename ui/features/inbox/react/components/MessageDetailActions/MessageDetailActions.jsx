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

import {IconButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconMoreLine, IconReplyLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import PropTypes from 'prop-types'
import React from 'react'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('conversations_2')

export const MessageDetailActions = ({...props}) => {
  return (
    <>
      {props.onReply && (
        <Tooltip renderTip={I18n.t('Reply')} on={['hover', 'focus']}>
          <IconButton
            size="small"
            margin="0 x-small 0 0"
            screenReaderLabel={I18n.t('Reply to %{authorName}', {
              authorName: props.authorName,
            })}
            onClick={props.onReply}
            data-testid="message-reply"
            withBackground={false}
            withBorder={false}
          >
            <IconReplyLine />
          </IconButton>
        </Tooltip>
      )}
      <Menu
        placement="bottom"
        trigger={
          <Tooltip renderTip={I18n.t('More options')} on={['hover', 'focus']}>
            <IconButton
              margin="0 x-small 0 0"
              size="small"
              data-testid="message-more-options"
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('More options for message from %{authorName}', {
                authorName: props.authorName,
              })}
            >
              <IconMoreLine />
            </IconButton>
          </Tooltip>
        }
      >
        {props.onReplyAll && (
          <Menu.Item value="reply-all" onSelect={props.onReplyAll}>
            {I18n.t('Reply All')}
          </Menu.Item>
        )}
        {props.onForward && (
          <Menu.Item value="forward" onSelect={props.onForward}>
            {I18n.t('Forward')}
          </Menu.Item>
        )}
        <Menu.Item value="delete" onSelect={props.onDelete} data-testid="message-delete">
          {I18n.t('Delete')}
        </Menu.Item>
      </Menu>
    </>
  )
}

MessageDetailActions.propTypes = {
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func,
  onDelete: PropTypes.func,
  onForward: PropTypes.func,
  authorName: PropTypes.string,
}

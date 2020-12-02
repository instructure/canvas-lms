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

import {Avatar} from '@instructure/ui-avatar'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconMiniArrowDownLine, IconReplyLine, IconSettingsLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
// import {t} from 'i18n!conversations'
// TODO: replace with frd translation function
const t = str => str

export const MessageDetailItem = ({...props}) => {
  const formatParticipants = () => {
    const participantsStr = props.conversationMessage.participants
      .filter(p => p.name !== props.conversationMessage.author.name)
      .reduce((prev, curr) => {
        return prev + ', ' + curr.name
      }, '')

    return (
      <Text as="div">
        <TruncateText>
          <b>{props.conversationMessage.author.name}</b>
          {participantsStr}
        </TruncateText>
      </Text>
    )
  }

  const renderActionButtons = () => {
    return (
      <>
        <Tooltip renderTip={t('Reply')} on={['hover', 'focus']}>
          <IconButton
            size="small"
            margin="0 x-small 0 0"
            screenReaderLabel={t('Reply')}
            onClick={() => props.handleOptionSelect('reply')}
          >
            <IconReplyLine />
          </IconButton>
        </Tooltip>
        <Menu
          placement="bottom"
          onSelect={(event, value) => {
            props.handleOptionSelect(value)
          }}
          trigger={
            <Tooltip renderTip={t('More options')} on={['hover', 'focus']}>
              <Button margin="0 x-small 0 0" size="small" renderIcon={IconSettingsLine}>
                <ScreenReaderContent>{t('More options')}</ScreenReaderContent>
                <IconMiniArrowDownLine />
              </Button>
            </Tooltip>
          }
        >
          <Menu.Item value="reply-all">{t('Reply All')}</Menu.Item>
          <Menu.Item value="forward">{t('Forward')}</Menu.Item>
          <Menu.Item value="delete">{t('Delete')}</Menu.Item>
        </Menu>
      </>
    )
  }

  return (
    <>
      <Flex>
        <Flex.Item>
          <Avatar
            margin="small small small none"
            name={props.conversationMessage.author.name}
            src={props.conversationMessage.author.avatar_url}
          />
        </Flex.Item>
        <Flex.Item shouldGrow>
          {formatParticipants()}
          <View as="div" margin="xx-small none xxx-small">
            <Text color="secondary" weight="light">
              {props.context.name}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item textAlign="end">
          <View as="div" margin="none none x-small">
            <Text weight="light">{props.conversationMessage.created_at}</Text>
          </View>
          {renderActionButtons()}
        </Flex.Item>
      </Flex>
      <Text>{props.conversationMessage.body}</Text>
    </>
  )
}

MessageDetailItem.propTypes = {
  // TODO: not sure yet the exact shape of the data that will be fetched, so these will likely change
  conversationMessage: PropTypes.object,
  context: PropTypes.object,
  handleOptionSelect: PropTypes.func
}

MessageDetailItem.defaultProps = {
  conversationMessage: {},
  context: {}
}

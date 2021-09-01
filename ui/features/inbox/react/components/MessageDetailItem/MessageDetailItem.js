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
import {Flex} from '@instructure/ui-flex'
import {MessageDetailActions} from '../MessageDetailActions/MessageDetailActions'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!conversations_2'

export const MessageDetailItem = ({...props}) => {
  const formatParticipants = () => {
    const participantsStr = props.conversationMessage.recipients
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

  const dateOptions = {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric'
  }

  const createdAt = Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
    new Date(props.conversationMessage.createdAt)
  )

  return (
    <>
      <Flex>
        <Flex.Item>
          <Avatar
            margin="small small small none"
            name={props.conversationMessage.author.name}
            src={props.conversationMessage.author.avatarUrl}
          />
        </Flex.Item>
        <Flex.Item shouldGrow>
          {formatParticipants()}
          <View as="div" margin="xx-small none xxx-small">
            <Text color="secondary" weight="light">
              {props.contextName}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item textAlign="end">
          <View as="div" margin="none none x-small">
            <Text weight="light">{createdAt}</Text>
          </View>
          <MessageDetailActions handleOptionSelect={props.handleOptionSelect} />
        </Flex.Item>
      </Flex>
      <Text>{props.conversationMessage.body}</Text>
    </>
  )
}

MessageDetailItem.propTypes = {
  // TODO: not sure yet the exact shape of the data that will be fetched, so these will likely change
  conversationMessage: PropTypes.object,
  contextName: PropTypes.string,
  handleOptionSelect: PropTypes.func
}

MessageDetailItem.defaultProps = {
  conversationMessage: {}
}

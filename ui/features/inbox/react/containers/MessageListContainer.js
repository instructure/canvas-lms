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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CONVERSATIONS_QUERY} from '../../graphql/Queries'
import {UPDATE_CONVERSATION_PARTICIPANTS} from '../../graphql/Mutations'
import {MessageListHolder} from '../components/MessageListHolder/MessageListHolder'
import I18n from 'i18n!conversations_2'
import {Mask} from '@instructure/ui-overlays'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery, useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'

const MessageListContainer = ({course, scope, onSelectMessage}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const userID = ENV.current_user_id?.toString()

  const [starChangeConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted(data) {
      if (data.updateConversationParticipants.errors) {
        setOnFailure(I18n.t('There was an unexpected error updating the conversation participants'))
      } else {
        const isStarred =
          data.updateConversationParticipants.conversationParticipants[0].label === 'starred'

        if (isStarred) {
          setOnSuccess(I18n.t('The conversation has been successfully starred'))
        } else {
          setOnSuccess(I18n.t('The conversation has been successfully unstarred'))
        }
      }
    },
    onError() {
      setOnFailure(I18n.t('There was an unexpected error updating the conversation participants'))
    }
  })

  const handleStar = (starred, conversationId) => {
    starChangeConversationParticipants({
      variables: {
        conversationIds: [conversationId],
        starred
      }
    })
  }

  const {loading, error, data} = useQuery(CONVERSATIONS_QUERY, {
    variables: {userID, scope, course},
    fetchPolicy: 'cache-and-network'
  })

  if (loading) {
    return (
      <View as="div" style={{position: 'relative'}} height="100%">
        <Mask>
          <Spinner renderTitle={() => I18n.t('Loading Message List')} variant="inverse" />
        </Mask>
      </View>
    )
  }

  if (error) {
    setOnFailure(I18n.t('Unable to load messages.'))
  }

  return (
    <MessageListHolder
      conversations={data?.legacyNode?.conversationsConnection?.nodes}
      onOpen={() => {}}
      onSelect={onSelectMessage}
      onStar={handleStar}
    />
  )
}

export default MessageListContainer

MessageListContainer.propTypes = {
  course: PropTypes.string,
  scope: PropTypes.string,
  onSelectMessage: PropTypes.func
}

MessageListContainer.defaultProps = {
  scope: 'inbox',
  onSelectMessage: () => {}
}

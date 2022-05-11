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
import {ConversationContext} from '../../util/constants'
import {CONVERSATIONS_QUERY, VIEWABLE_SUBMISSIONS_QUERY} from '../../graphql/Queries'
import {UPDATE_CONVERSATION_PARTICIPANTS} from '../../graphql/Mutations'
import {ConversationListHolder} from '../components/ConversationListHolder/ConversationListHolder'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mask} from '@instructure/ui-overlays'
import PropTypes from 'prop-types'
import React, {useContext, useMemo} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery, useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {inboxConversationsWrapper} from '../../util/utils'

const I18n = useI18nScope('conversations_2')

const ConversationListContainer = ({course, scope, onSelectConversation, userFilter}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {isSubmissionCommentsType} = useContext(ConversationContext)

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

  const conversationsQuery = useQuery(CONVERSATIONS_QUERY, {
    variables: {userID, scope, filter: [userFilter, course]},
    fetchPolicy: 'cache-and-network',
    skip: isSubmissionCommentsType
  })

  const submissionCommentsQuery = useQuery(VIEWABLE_SUBMISSIONS_QUERY, {
    variables: {userID, sort: 'desc'},
    skip: !isSubmissionCommentsType
  })

  const inboxItemData = useMemo(() => {
    const data = isSubmissionCommentsType
      ? submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.nodes
      : conversationsQuery.data?.legacyNode?.conversationsConnection?.nodes
    return inboxConversationsWrapper(data, isSubmissionCommentsType)
  }, [conversationsQuery.data, isSubmissionCommentsType, submissionCommentsQuery.data])

  if (conversationsQuery.loading || submissionCommentsQuery.loading) {
    return (
      <View as="div" style={{position: 'relative'}} height="100%">
        <Mask>
          <Spinner renderTitle={() => I18n.t('Loading Message List')} variant="inverse" />
        </Mask>
      </View>
    )
  }

  if (conversationsQuery.error || submissionCommentsQuery.error) {
    setOnFailure(I18n.t('Unable to load messages.'))
  }

  return (
    <ConversationListHolder
      conversations={inboxItemData}
      onOpen={() => {}}
      onSelect={onSelectConversation}
      onStar={handleStar}
    />
  )
}

export default ConversationListContainer

ConversationListContainer.propTypes = {
  course: PropTypes.string,
  userFilter: PropTypes.number,
  scope: PropTypes.string,
  onSelectConversation: PropTypes.func
}

ConversationListContainer.defaultProps = {
  scope: 'inbox',
  onSelectConversation: () => {}
}

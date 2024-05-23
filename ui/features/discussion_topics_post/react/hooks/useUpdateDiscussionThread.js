/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {updateDiscussionEntryRootEntryCounts, updateDiscussionTopicEntryCounts} from '../utils'
import {
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_THREAD_READ_STATE,
} from '../../graphql/Mutations'
import {useMutation, useApolloClient} from 'react-apollo'
import {useCallback, useContext} from 'react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_topics_post')

export const useUpdateDiscussionThread = ({
  discussionEntry,
  discussionTopic,
  setLoadedSubentries,
}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const client = useApolloClient()

  const resetDiscussionCache = () => {
    client.resetStore()
  }
  const [updateDiscussionThreadReadState] = useMutation(UPDATE_DISCUSSION_THREAD_READ_STATE, {
    update: resetDiscussionCache,
  })

  const updateDiscussionEntryParticipantCache = useCallback(
    (cache, result) => {
      if (
        discussionEntry.entryParticipant?.read !==
        result.data.updateDiscussionEntryParticipant.discussionEntry.entryParticipant?.read
      ) {
        const discussionUnreadCountChange = result.data.updateDiscussionEntryParticipant
          .discussionEntry.entryParticipant?.read
          ? -1
          : 1
        updateDiscussionTopicEntryCounts(cache, discussionTopic.id, {
          unreadCountChange: discussionUnreadCountChange,
        })

        if (result.data.updateDiscussionEntryParticipant.discussionEntry.rootEntryId) {
          updateDiscussionEntryRootEntryCounts(
            cache,
            result.data.updateDiscussionEntryParticipant.discussionEntry,
            discussionUnreadCountChange
          )
        }
      }
    },
    [discussionEntry, discussionTopic]
  )

  const updateLoadedSubentry = updatedEntry => {
    // if it's a subentry then we need to update the loadedSubentry.
    if (setLoadedSubentries) {
      setLoadedSubentries(loadedSubentries => {
        return loadedSubentries.map(entry =>
          !!updatedEntry.rootEntryId && entry.id === updatedEntry.id ? updatedEntry : entry
        )
      })
    }
  }

  const [updateDiscussionEntryParticipant] = useMutation(UPDATE_DISCUSSION_ENTRY_PARTICIPANT, {
    update: updateDiscussionEntryParticipantCache,
    onCompleted: data => {
      if (!data || !data.updateDiscussionEntryParticipant) {
        return null
      }
      updateLoadedSubentry(data.updateDiscussionEntryParticipant.discussionEntry)
      setOnSuccess(I18n.t('The reply was successfully updated.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the reply.'))
    },
  })

  const toggleUnread = useCallback(
    () =>
      updateDiscussionEntryParticipant({
        variables: {
          discussionEntryId: discussionEntry._id,
          read: !discussionEntry.entryParticipant?.read,
          forcedReadState: true,
        },
      }),
    [discussionEntry, updateDiscussionEntryParticipant]
  )

  return {
    updateDiscussionEntryParticipantCache,
    updateDiscussionEntryParticipant,
    updateLoadedSubentry,
    updateDiscussionThreadReadState,
    toggleUnread,
  }
}

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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CREATE_DISCUSSION_ENTRY} from '../../../graphql/Mutations'
import {DISCUSSION_QUERY} from '../../../graphql/Queries'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionThreadContainer} from '../DiscussionThreadContainer/DiscussionThreadContainer'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PER_PAGE} from '../../utils/constants'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ThreadPagination} from '../../components/ThreadPagination/ThreadPagination'
import {useMutation, useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const DiscussionThreadsContainer = props => {
  const [currentPage, setCurrentPage] = useState(0)
  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)

  const variables = {
    discussionID: props.discussionTopicId,
    perPage: PER_PAGE,
    page: btoa(currentPage * PER_PAGE)
  }

  const {loading, data} = useQuery(DISCUSSION_QUERY, {
    variables
  })

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.'))
    }
  })

  if (loading) {
    return <LoadingIndicator />
  }

  const threads = data.legacyNode.rootDiscussionEntriesConnection.nodes
  const totalPages = data.legacyNode.rootEntriesTotalPages

  return (
    <View as="div" margin="medium none none none">
      {threads?.map(thread => {
        return (
          <DiscussionThreadContainer
            key={`discussion-thread-${thread.id}`}
            assignment={props.discussionTopic?.assignment}
            discussionEntry={thread}
            createDiscussionEntry={text => {
              createDiscussionEntry({
                variables: {
                  discussionTopicId: ENV.discussion_topic_id,
                  parentEntryId: thread._id,
                  message: text
                }
              })
            }}
          />
        )
      })}
      {props.totalPages > 1 && (
        <ThreadPagination
          setPage={setCurrentPage}
          selectedPage={currentPage + 1}
          totalPages={totalPages}
        />
      )}
    </View>
  )
}

DiscussionThreadsContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionTopicId: PropTypes.string.isRequired,
  totalPages: PropTypes.number
}

export default DiscussionThreadsContainer

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

import {DISCUSSION_QUERY} from '../../../graphql/Queries'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionThreadContainer} from '../DiscussionThreadContainer/DiscussionThreadContainer'
import LoadingIndicator from '@canvas/loading-indicator'
import {PER_PAGE} from '../../utils/constants'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {ThreadPagination} from '../../components/ThreadPagination/ThreadPagination'
import {useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const DiscussionThreadsContainer = props => {
  const [currentPage, setCurrentPage] = useState(0)

  const variables = {
    discussionID: props.discussionTopicId,
    perPage: PER_PAGE,
    page: btoa(currentPage * PER_PAGE)
  }

  const {loading, data} = useQuery(DISCUSSION_QUERY, {
    variables
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

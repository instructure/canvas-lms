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
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {DiscussionThreadContainer} from '../DiscussionThreadContainer/DiscussionThreadContainer'
import LoadingIndicator from '@canvas/loading-indicator'
import {PageInfo} from '../../../graphql/PageInfo'
import {PER_PAGE} from '../../utils/constants'
import PropTypes from 'prop-types'
import React from 'react'
import {ThreadPagination} from '../../components/ThreadPagination/ThreadPagination'
import {useLazyQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'

export const DiscussionThreadsContainer = props => {
  let threads = props.threads
  let selectedPage = Math.ceil(atob(props.pageInfo.startCursor) / PER_PAGE)

  const [discussionTopicQuery, {called, loading, data}] = useLazyQuery(DISCUSSION_QUERY)

  if (called && loading) {
    return <LoadingIndicator />
  }

  if (called && data) {
    selectedPage = Math.ceil(
      atob(data.legacyNode.rootDiscussionEntriesConnection.pageInfo.startCursor) / PER_PAGE
    )
    threads = data.legacyNode.rootDiscussionEntriesConnection.nodes
  }

  const setPage = pageNumber => {
    discussionTopicQuery({
      variables: {
        discussionID: props.discussionTopicId,
        perPage: PER_PAGE,
        page: btoa(pageNumber * PER_PAGE)
      }
    })
  }

  return (
    <View as="div" margin="medium none none none">
      {threads?.map(thread => {
        return (
          <DiscussionThreadContainer
            key={`discussion-thread-${thread.id}`}
            assignment={props.discussionTopic?.assignment}
            discussionEntry={thread}
            discussionTopicGraphQLId={props.discussionTopic.id}
          />
        )
      })}
      {props.totalPages > 1 && (
        <ThreadPagination
          setPage={setPage}
          selectedPage={selectedPage}
          totalPages={props.totalPages}
        />
      )}
    </View>
  )
}

DiscussionThreadsContainer.propTypes = {
  discussionTopic: Discussion.shape,
  discussionTopicId: PropTypes.string.isRequired,
  threads: PropTypes.arrayOf(DiscussionEntry.shape),
  pageInfo: PageInfo.shape.isRequired,
  totalPages: PropTypes.number
}

export default DiscussionThreadsContainer

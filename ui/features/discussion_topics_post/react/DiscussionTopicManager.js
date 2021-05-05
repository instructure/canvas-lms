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

import {DISCUSSION_QUERY} from '../graphql/Queries'
import {DiscussionThreadsContainer} from './containers/DiscussionThreadsContainer/DiscussionThreadsContainer'
import {DiscussionTopicContainer} from './containers/DiscussionTopicContainer/DiscussionTopicContainer'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import I18n from 'i18n!discussion_topics_post'
import LoadingIndicator from '@canvas/loading-indicator'
import {PER_PAGE} from './utils/constants'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {CREATE_DISCUSSION_ENTRY} from '../graphql/Mutations'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const DiscussionTopicManager = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const variables = {
    discussionID: props.discussionTopicId,
    perPage: PER_PAGE,
    page: btoa(0)
  }
  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {variables})

  const updateCache = (cache, result) => {
    try {
      const lastPage = discussionTopicQuery.data.legacyNode.rootEntriesTotalPages - 1
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables, page: btoa(lastPage * PER_PAGE)}
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      if (currentDiscussion && newDiscussionEntry) {
        currentDiscussion.legacyNode.rootDiscussionEntriesConnection.nodes.push(newDiscussionEntry)

        // TODO: Handle sorting.
        cache.writeQuery({...options, data: currentDiscussion})
      }
      // eslint-disable-next-line no-empty
    } catch (e) {}
  }

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    update: updateCache,
    onCompleted: () => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error creating the discussion entry.'))
    }
  })

  if (discussionTopicQuery.loading) {
    return <LoadingIndicator />
  }

  if (discussionTopicQuery.error || !discussionTopicQuery?.data?.legacyNode) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Discussion Topic initial query error')}
        errorCategory={I18n.t('Discussion Topic Post Error Page')}
      />
    )
  }

  return (
    <>
      <DiscussionTopicContainer
        discussionTopic={discussionTopicQuery.data.legacyNode}
        createDiscussionEntry={text => {
          createDiscussionEntry({
            variables: {
              discussionTopicId: ENV.discussion_topic_id,
              message: text
            }
          })
        }}
      />
      <DiscussionThreadsContainer
        discussionTopic={discussionTopicQuery.data.legacyNode}
        discussionTopicId={props.discussionTopicId}
        threads={discussionTopicQuery.data.legacyNode.rootDiscussionEntriesConnection.nodes}
        pageInfo={discussionTopicQuery.data.legacyNode.rootDiscussionEntriesConnection.pageInfo}
        totalPages={discussionTopicQuery.data.legacyNode.rootEntriesTotalPages}
      />
    </>
  )
}

DiscussionTopicManager.propTypes = {
  discussionTopicId: PropTypes.string.isRequired
}

export default DiscussionTopicManager

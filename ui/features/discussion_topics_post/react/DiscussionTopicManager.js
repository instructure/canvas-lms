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
import {CREATE_DISCUSSION_ENTRY} from '../graphql/Mutations'
import {DISCUSSION_QUERY} from '../graphql/Queries'
import {DiscussionPostToolbarContainer} from './containers/DiscussionPostToolbarContainer/DiscussionPostToolbarContainer'
import {DiscussionThreadsContainer} from './containers/DiscussionThreadsContainer/DiscussionThreadsContainer'
import {DiscussionTopicContainer} from './containers/DiscussionTopicContainer/DiscussionTopicContainer'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {HIGHLIGHT_TIMEOUT, PER_PAGE, SearchContext} from './utils/constants'
import I18n from 'i18n!discussion_topics_post'
import {IsolatedViewContainer} from './containers/IsolatedViewContainer/IsolatedViewContainer'
import LoadingIndicator from '@canvas/loading-indicator'
import {NoResultsFound} from './components/NoResultsFound/NoResultsFound'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'

const getOptimisticResponse = text => {
  return {
    createDiscussionEntry: {
      discussionEntry: {
        id: 'PLACEHOLDER',
        _id: 'PLACEHOLDER',
        createdAt: new Date(),
        updatedAt: new Date(),
        deleted: false,
        message: text,
        ratingCount: null,
        ratingSum: null,
        rating: false,
        read: true,
        forcedReadState: false,
        subentriesCount: null,
        rootEntryParticipantCounts: {
          unreadCount: 0,
          repliesCount: 0,
          __typename: 'DiscussionEntryCounts'
        },
        author: {
          id: 'PLACEHOLDER',
          _id: ENV.current_user.id,
          avatarUrl: ENV.current_user.avatar_image_url,
          displayName: ENV.current_user.display_name,
          courseRoles: [],
          __typename: 'User'
        },
        editor: null,
        lastReply: null,
        permissions: {
          attach: false,
          create: false,
          delete: false,
          rate: false,
          read: false,
          reply: false,
          update: false,
          viewRating: false,
          __typename: 'DiscussionEntryPermissions'
        },
        rootEntry: null,
        discussionTopic: null,
        parent: null,
        __typename: 'DiscussionEntry'
      },
      errors: null,
      __typename: 'CreateDiscussionEntryPayload'
    }
  }
}

const DiscussionTopicManager = props => {
  const [searchTerm, setSearchTerm] = useState('')
  const [filter, setFilter] = useState('all')
  const [sort, setSort] = useState('desc')
  const [pageNumber, setPageNumber] = useState(0)
  const searchContext = {
    searchTerm,
    setSearchTerm,
    filter,
    setFilter,
    sort,
    setSort,
    pageNumber,
    setPageNumber
  }

  const goToTopic = () => {
    setSearchTerm('')
    closeIsolatedView()
    setIsTopicHighlighted(true)
  }

  // Isolated View State
  const [isolatedEntryId, setIsolatedEntryId] = useState(null)
  const [isolatedViewOpen, setIsolatedViewOpen] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)

  // Highlight State
  const [isTopicHighlighted, setIsTopicHighlighted] = useState(false)
  const [highlightEntryId, setHighlightEntryId] = useState(null)
  const [relativeEntryId, setRelativeEntryId] = useState(null)

  useEffect(() => {
    if (isTopicHighlighted) {
      setTimeout(() => {
        setIsTopicHighlighted(false)
      }, HIGHLIGHT_TIMEOUT)
    }
  }, [isTopicHighlighted])

  useEffect(() => {
    if (highlightEntryId) {
      setTimeout(() => {
        setHighlightEntryId(null)
      }, HIGHLIGHT_TIMEOUT)
    }
  }, [highlightEntryId])

  const openIsolatedView = (discussionEntryId, withRCE, relativeId = null) => {
    setIsolatedEntryId(discussionEntryId)
    setIsolatedViewOpen(true)
    setEditorExpanded(withRCE)
    setRelativeEntryId(relativeId)
  }

  const closeIsolatedView = () => {
    setIsolatedViewOpen(false)
  }

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const variables = {
    discussionID: props.discussionTopicId,
    perPage: PER_PAGE,
    page: btoa(pageNumber * PER_PAGE),
    searchTerm,
    rootEntries: !searchTerm && filter === 'all',
    filter,
    sort,
    courseID: window.ENV?.course_id
  }

  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {variables})

  const updateCache = (cache, result) => {
    try {
      const lastPage = discussionTopicQuery.data.legacyNode.entriesTotalPages - 1
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables, page: btoa(lastPage * PER_PAGE)}
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      if (currentDiscussion && newDiscussionEntry) {
        currentDiscussion.legacyNode.entryCounts.repliesCount += 1
        currentDiscussion.legacyNode.discussionEntriesConnection.nodes.push(newDiscussionEntry)

        cache.writeQuery({...options, data: currentDiscussion})
      }
    } catch (e) {
      discussionTopicQuery.refetch(variables)
    }
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

  if (discussionTopicQuery.loading && !searchTerm && filter === 'all') {
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
    <SearchContext.Provider value={searchContext}>
      <DiscussionPostToolbarContainer discussionTopic={discussionTopicQuery.data.legacyNode} />
      <DiscussionTopicContainer
        discussionTopic={discussionTopicQuery.data.legacyNode}
        createDiscussionEntry={text => {
          createDiscussionEntry({
            variables: {
              discussionTopicId: ENV.discussion_topic_id,
              message: text
            },
            optimisticResponse: getOptimisticResponse(text)
          })
        }}
        isHighlighted={isTopicHighlighted}
      />
      {discussionTopicQuery.data.legacyNode.discussionEntriesConnection.nodes.length === 0 &&
      (searchTerm || filter === 'unread') ? (
        <NoResultsFound />
      ) : (
        <DiscussionThreadsContainer
          discussionTopic={discussionTopicQuery.data.legacyNode}
          onOpenIsolatedView={(discussionEntryId, withRCE, relativeId) => {
            setHighlightEntryId(relativeId)
            openIsolatedView(discussionEntryId, withRCE, relativeId)
          }}
          goToTopic={goToTopic}
        />
      )}
      {ENV.isolated_view && isolatedEntryId && (
        <IsolatedViewContainer
          relativeEntryId={relativeEntryId}
          discussionTopic={discussionTopicQuery.data.legacyNode}
          discussionEntryId={isolatedEntryId}
          open={isolatedViewOpen}
          RCEOpen={editorExpanded}
          setRCEOpen={setEditorExpanded}
          onClose={closeIsolatedView}
          onOpenIsolatedView={openIsolatedView}
          goToTopic={goToTopic}
          highlightEntryId={highlightEntryId}
          setHighlightEntryId={setHighlightEntryId}
        />
      )}
    </SearchContext.Provider>
  )
}

DiscussionTopicManager.propTypes = {
  discussionTopicId: PropTypes.string.isRequired
}

export default DiscussionTopicManager

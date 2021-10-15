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
import {DiscussionTopicToolbarContainer} from './containers/DiscussionTopicToolbarContainer/DiscussionTopicToolbarContainer'
import {DiscussionTopicRepliesContainer} from './containers/DiscussionTopicRepliesContainer/DiscussionTopicRepliesContainer'
import {DiscussionTopicContainer} from './containers/DiscussionTopicContainer/DiscussionTopicContainer'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {getOptimisticResponse} from './utils'
import {HIGHLIGHT_TIMEOUT, PER_PAGE, SearchContext} from './utils/constants'
import I18n from 'i18n!discussion_topics_post'
import {IsolatedViewContainer} from './containers/IsolatedViewContainer/IsolatedViewContainer'
import LoadingIndicator from '@canvas/loading-indicator'
import {NoResultsFound} from './components/NoResultsFound/NoResultsFound'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'

const DiscussionTopicManager = props => {
  const [searchTerm, setSearchTerm] = useState('')
  const [filter, setFilter] = useState('all')
  const [sort, setSort] = useState('desc')
  const [pageNumber, setPageNumber] = useState(0)
  const [searchPageNumber, setSearchPageNumber] = useState(0)
  const searchContext = {
    searchTerm,
    setSearchTerm,
    filter,
    setFilter,
    sort,
    setSort,
    pageNumber,
    setPageNumber,
    searchPageNumber,
    setSearchPageNumber
  }

  const goToTopic = () => {
    setSearchTerm('')
    closeIsolatedView()
    setIsTopicHighlighted(true)
  }

  // Isolated View State
  const [isolatedEntryId, setIsolatedEntryId] = useState(null)
  const [replyFromId, setReplyFromId] = useState(null)
  const [isolatedViewOpen, setIsolatedViewOpen] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)

  // Highlight State
  const [isTopicHighlighted, setIsTopicHighlighted] = useState(false)
  const [highlightEntryId, setHighlightEntryId] = useState(null)
  const [relativeEntryId, setRelativeEntryId] = useState(null)

  // Reset search to 0 when inactive
  useEffect(() => {
    if (searchTerm && pageNumber !== 0) {
      setPageNumber(0)
    } else if (!searchTerm && searchPageNumber !== 0) {
      setSearchPageNumber(0)
    }
  }, [pageNumber, searchPageNumber, searchTerm])

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

  const openIsolatedView = (discussionEntryId, isolatedId, withRCE, relativeId = null) => {
    setReplyFromId(discussionEntryId)
    setIsolatedEntryId(isolatedId || discussionEntryId)
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
    page: searchTerm ? btoa(searchPageNumber * PER_PAGE) : btoa(pageNumber * PER_PAGE),
    searchTerm,
    rootEntries: !searchTerm && filter === 'all',
    filter,
    sort,
    courseID: window.ENV?.course_id
  }

  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {
    variables,
    fetchPolicy: searchTerm ? 'no-cache' : 'cache-and-network'
  })

  const updateDraftCache = (cache, result) => {
    try {
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables}
      }
      const newDiscussionEntryDraft = result.data.createDiscussionEntryDraft.discussionEntryDraft
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      if (currentDiscussion && newDiscussionEntryDraft) {
        currentDiscussion.legacyNode.discussionEntryDraftsConnection.nodes =
          currentDiscussion.legacyNode.discussionEntryDraftsConnection.nodes.filter(
            draft => draft.id !== newDiscussionEntryDraft.id
          )
        currentDiscussion.legacyNode.discussionEntryDraftsConnection.nodes.push(
          newDiscussionEntryDraft
        )

        cache.writeQuery({...options, data: currentDiscussion})
      }
    } catch (e) {
      // do nothing for errors updating the cache on a draft
    }
  }

  const removeDraftFromDiscussionCache = (cache, result) => {
    try {
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables}
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      currentDiscussion.legacyNode.discussionEntryDraftsConnection.nodes =
        currentDiscussion.legacyNode.discussionEntryDraftsConnection.nodes.filter(
          draft =>
            draft.rootEntryId !== newDiscussionEntry.rootEntryId &&
            draft.discussionTopicID !== newDiscussionEntry.discussionTopicID
        )
      cache.writeQuery({...options, data: currentDiscussion})
    } catch (e) {
      // do nothing for errors updating the cache on a draft
    }
  }

  const updateCache = (cache, result) => {
    try {
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables}
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      if (currentDiscussion && newDiscussionEntry) {
        currentDiscussion.legacyNode.entryCounts.repliesCount += 1
        removeDraftFromDiscussionCache(cache, result)
        if (variables.sort === 'desc') {
          currentDiscussion.legacyNode.discussionEntriesConnection.nodes.unshift(newDiscussionEntry)
        } else {
          currentDiscussion.legacyNode.discussionEntriesConnection.nodes.push(newDiscussionEntry)
        }

        cache.writeQuery({...options, data: currentDiscussion})
      }
    } catch (e) {
      discussionTopicQuery.refetch(variables)
    }
  }

  const [createDiscussionEntry] = useMutation(CREATE_DISCUSSION_ENTRY, {
    update: updateCache,
    onCompleted: data => {
      setOnSuccess(I18n.t('The discussion entry was successfully created.'))
      setHighlightEntryId(data.createDiscussionEntry.discussionEntry._id)
      if (sort === 'asc') {
        setPageNumber(discussionTopicQuery.data.legacyNode.entriesTotalPages - 1)
      }
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
      <DiscussionTopicToolbarContainer discussionTopic={discussionTopicQuery.data.legacyNode} />
      <DiscussionTopicContainer
        updateDraftCache={updateDraftCache}
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
        <DiscussionTopicRepliesContainer
          discussionTopic={discussionTopicQuery.data.legacyNode}
          updateDraftCache={updateDraftCache}
          removeDraftFromDiscussionCache={removeDraftFromDiscussionCache}
          onOpenIsolatedView={(discussionEntryId, isolatedId, withRCE, relativeId, highlightId) => {
            setHighlightEntryId(highlightId)
            openIsolatedView(discussionEntryId, isolatedId, withRCE, relativeId)
          }}
          goToTopic={goToTopic}
          highlightEntryId={highlightEntryId}
          isSearchResults={!!searchTerm}
        />
      )}
      {ENV.isolated_view && isolatedEntryId && (
        <IsolatedViewContainer
          relativeEntryId={relativeEntryId}
          removeDraftFromDiscussionCache={removeDraftFromDiscussionCache}
          updateDraftCache={updateDraftCache}
          discussionTopic={discussionTopicQuery.data.legacyNode}
          discussionEntryId={isolatedEntryId}
          replyFromId={replyFromId}
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

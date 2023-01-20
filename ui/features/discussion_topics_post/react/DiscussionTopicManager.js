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
import {getOptimisticResponse, responsiveQuerySizes} from './utils'
import {
  HIGHLIGHT_TIMEOUT,
  SearchContext,
  DiscussionManagerUtilityContext,
  AllThreadsState,
} from './utils/constants'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IsolatedViewContainer} from './containers/IsolatedViewContainer/IsolatedViewContainer'
import LoadingIndicator from '@canvas/loading-indicator'
import {NoResultsFound} from './components/NoResultsFound/NoResultsFound'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {SplitScreenViewContainer} from './containers/SplitScreenViewContainer/SplitScreenViewContainer'
import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Mask} from '@instructure/ui-overlays'
import {Responsive} from '@instructure/ui-responsive'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_topics_post')

const DiscussionTopicManager = props => {
  const [searchTerm, setSearchTerm] = useState('')
  const [filter, setFilter] = useState('all')
  const [unreadBefore, setUnreadBefore] = useState('')
  const [sort, setSort] = useState('desc')
  const [pageNumber, setPageNumber] = useState(ENV.current_page)
  const [searchPageNumber, setSearchPageNumber] = useState(0)
  const [allThreadsStatus, setAllThreadsStatus] = useState(AllThreadsState.None)
  const [expandedThreads, setExpandedThreads] = useState([])
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
    setSearchPageNumber,
    allThreadsStatus,
    setAllThreadsStatus,
    expandedThreads,
    setExpandedThreads,
  }
  const [userSplitScreenPreference, setUserSplitScreenPreference] = useState(
    ENV.DISCUSSION?.preferences?.discussions_splitscreen_view || false
  )

  const goToTopic = () => {
    setSearchTerm('')
    closeView()
    setIsTopicHighlighted(true)
  }

  // Isolated View State
  const [threadParentEntryId, setThreadParentEntryId] = useState(
    ENV.isolated_view
      ? ENV.discussions_deep_link?.root_entry_id
      : ENV.discussions_deep_link?.parent_id
  )
  const [replyFromId, setReplyFromId] = useState(null)
  const [isolatedViewOpen, setIsolatedViewOpen] = useState(
    !ENV.split_screen_view && !!ENV.discussions_deep_link?.root_entry_id
  )

  // split screen view
  const [isSplitScreenViewOpen, setSplitScreenViewOpen] = useState(
    ENV.split_screen_view &&
      ENV.DISCUSSION?.preferences?.discussions_splitscreen_view &&
      !!(ENV.discussions_deep_link?.parent_id
        ? ENV.discussions_deep_link?.parent_id
        : ENV.discussions_deep_link?.entry_id)
  )
  const [isSplitScreenViewOverlayed, setSplitScreenViewOverlayed] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)

  // Highlight State
  const [isTopicHighlighted, setIsTopicHighlighted] = useState(false)
  const [highlightEntryId, setHighlightEntryId] = useState(ENV.discussions_deep_link?.entry_id)
  const [relativeEntryId, setRelativeEntryId] = useState(null)

  const [isUserMissingInitialPost, setIsUserMissingInitialPost] = useState(null)

  const discussionManagerUtilities = {
    replyFromId,
    setReplyFromId,
    userSplitScreenPreference,
    setUserSplitScreenPreference,
    highlightEntryId,
    setHighlightEntryId,
  }

  // Unread filter
  // This introduces a double query for DISCUSSION_QUERY when filter changes
  useEffect(() => {
    if (filter === 'unread' && !unreadBefore) {
      setUnreadBefore(new Date(Date.now()).toISOString())
    } else if (filter !== 'unread') {
      setUnreadBefore('')
    }
    setPageNumber(0)
    setSearchPageNumber(0)
  }, [filter, unreadBefore])

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

  const openView = (discussionEntryId, isolatedId, withRCE, relativeId = null) => {
    if (ENV.isolated_view) {
      openIsolatedView(discussionEntryId, isolatedId, withRCE, relativeId)
    }
    if (ENV.split_screen_view) {
      openSplitScreenView(discussionEntryId, withRCE, relativeId)
    }
  }

  const openIsolatedView = (discussionEntryId, isolatedId, withRCE, relativeId = null) => {
    setReplyFromId(discussionEntryId)
    setThreadParentEntryId(isolatedId || discussionEntryId)
    setIsolatedViewOpen(true)
    setEditorExpanded(withRCE)
    setRelativeEntryId(relativeId)
  }

  const openSplitScreenView = (discussionEntryId, withRCE, relativeId = null) => {
    setThreadParentEntryId(discussionEntryId)
    setSplitScreenViewOpen(true)
    setEditorExpanded(withRCE)
    setRelativeEntryId(relativeId)
  }

  const closeView = () => {
    if (ENV.isolated_view) {
      setIsolatedViewOpen(false)
    }
    if (ENV.split_screen_view) {
      setSplitScreenViewOpen(false)
    }
  }

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const variables = {
    discussionID: props.discussionTopicId,
    perPage: ENV.per_page,
    page: searchTerm ? btoa(searchPageNumber * ENV.per_page) : btoa(pageNumber * ENV.per_page),
    searchTerm,
    rootEntries: !searchTerm && filter === 'all',
    filter,
    sort,
    courseID: window.ENV?.course_id,
    unreadBefore,
  }

  // Unread and unreadBefore both useState and trigger useQuery. We need to wait until both are set.
  // Also when switching from unread the same issue causes 2 queries when unreadBefore switches to '',
  // but unreadBefore only applies to unread filter. So we dont need the extra query.
  const waitForUnreadFilter =
    (filter === 'unread' && !unreadBefore) || (filter !== 'unread' && unreadBefore)

  // in some cases, we want to refresh the results rather that use the current cache:
  // in the case: 'isUserMissingInitialPost' the cache is empty so we need to get the entries.
  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {
    variables,
    fetchPolicy: isUserMissingInitialPost || searchTerm ? 'network-only' : 'cache-and-network',
    skip: waitForUnreadFilter,
  })

  const updateDraftCache = (cache, result) => {
    try {
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables},
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
        variables: {...variables},
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
        variables: {...variables},
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))

      // if the current user hasn't made the required inital post, then this entry will be it.
      // In that case, we are required to do a page refresh to get all the entries (implemented with isUserMissingInitialPost)
      // thus we bascially want to not do 'else if (currentDiscussion && newDiscussionEntry)' which contains updateCache logic.
      // Discussion.initialPostRequiredForCurrentUser is based on user and topic so if the user meets this reuqire, then
      // this doesnt run and cacheing resumes as normal.
      if (currentDiscussion.legacyNode.initialPostRequiredForCurrentUser) {
        setIsUserMissingInitialPost(currentDiscussion.legacyNode.initialPostRequiredForCurrentUser)
      } else if (currentDiscussion && newDiscussionEntry) {
        // if we have a new entry update the counts, because we are about to add to the cache (something useMutation dont do, that useQuery does)
        currentDiscussion.legacyNode.entryCounts.repliesCount += 1
        removeDraftFromDiscussionCache(cache, result)
        // add the new entry to the current entries in the cache
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
    },
  })

  // why || waitForUnreadFilter: when waitForUnreadFilter, discussionTopicQuery is skipped, but this does not set loading.
  // why && !searchTerm: this is for the search if you type it triggers useQuery and you lose the search.
  // why not just discussionTopicQuery.loading, it doesnt play nice with search term.
  if (
    (discussionTopicQuery.loading && !searchTerm) ||
    waitForUnreadFilter ||
    (discussionTopicQuery.loading &&
      discussionTopicQuery?.data &&
      Object.keys(discussionTopicQuery.data).length === 0)
  ) {
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
      <DiscussionManagerUtilityContext.Provider value={discussionManagerUtilities}>
        <Responsive
          match="media"
          query={responsiveQuerySizes({mobile: true, desktop: true})}
          props={{
            mobile: {
              viewPortWidth: '100vw',
            },
            desktop: {
              viewPortWidth: '50vw',
            },
          }}
          render={responsiveProps => {
            return (
              <DrawerLayout
                onOverlayTrayChange={isOverlayed => {
                  setSplitScreenViewOverlayed(isOverlayed)
                }}
              >
                {isSplitScreenViewOverlayed && isSplitScreenViewOpen && (
                  <Mask onClick={() => setSplitScreenViewOpen(false)} />
                )}
                <DrawerLayout.Content label="Splitscreen View Content">
                  <View display="block" padding="medium medium 0 xx-small" height="100vh">
                    <DiscussionTopicToolbarContainer
                      discussionTopic={discussionTopicQuery.data.legacyNode}
                      setUserSplitScreenPreference={setUserSplitScreenPreference}
                      userSplitScreenPreference={userSplitScreenPreference}
                      closeView={closeView}
                    />
                    <DiscussionTopicContainer
                      updateDraftCache={updateDraftCache}
                      discussionTopic={discussionTopicQuery.data.legacyNode}
                      createDiscussionEntry={(message, fileId, isAnonymousAuthor) => {
                        createDiscussionEntry({
                          variables: {
                            discussionTopicId: ENV.discussion_topic_id,
                            message,
                            fileId,
                            courseID: ENV.course_id,
                            isAnonymousAuthor,
                          },
                          optimisticResponse: getOptimisticResponse({
                            message,
                            isAnonymous:
                              !!discussionTopicQuery.data.legacyNode.anonymousState &&
                              discussionTopicQuery.data.legacyNode.canReplyAnonymously,
                          }),
                        })
                      }}
                      isHighlighted={isTopicHighlighted}
                      onDiscussionReplyPost={() => {
                        // When post requires a reply, check to see if we can refatch after initial post
                        if (
                          discussionTopicQuery.data.legacyNode.availableForUser &&
                          discussionTopicQuery.data.legacyNode.initialPostRequiredForCurrentUser
                        ) {
                          discussionTopicQuery.refetch(variables)
                        }
                      }}
                    />

                    {discussionTopicQuery.data.legacyNode.discussionEntriesConnection.nodes
                      .length === 0 &&
                    (searchTerm || filter === 'unread') ? (
                      <NoResultsFound />
                    ) : (
                      discussionTopicQuery.data.legacyNode.availableForUser && (
                        <DiscussionTopicRepliesContainer
                          discussionTopic={discussionTopicQuery.data.legacyNode}
                          updateDraftCache={updateDraftCache}
                          removeDraftFromDiscussionCache={removeDraftFromDiscussionCache}
                          onOpenIsolatedView={(
                            discussionEntryId,
                            isolatedId,
                            withRCE,
                            relativeId,
                            highlightId
                          ) => {
                            setHighlightEntryId(highlightId)
                            openView(discussionEntryId, isolatedId, withRCE, relativeId)
                          }}
                          goToTopic={goToTopic}
                          highlightEntryId={highlightEntryId}
                          setHighlightEntryId={setHighlightEntryId}
                          isSearchResults={!!searchTerm}
                          userSplitScreenPreference={userSplitScreenPreference}
                        />
                      )
                    )}
                    {ENV.isolated_view && threadParentEntryId && (
                      <IsolatedViewContainer
                        relativeEntryId={relativeEntryId}
                        removeDraftFromDiscussionCache={removeDraftFromDiscussionCache}
                        updateDraftCache={updateDraftCache}
                        discussionTopic={discussionTopicQuery.data.legacyNode}
                        discussionEntryId={threadParentEntryId}
                        replyFromId={replyFromId}
                        open={isolatedViewOpen}
                        RCEOpen={editorExpanded}
                        setRCEOpen={setEditorExpanded}
                        onClose={closeView}
                        onOpenIsolatedView={openIsolatedView}
                        goToTopic={goToTopic}
                        highlightEntryId={highlightEntryId}
                        setHighlightEntryId={setHighlightEntryId}
                      />
                    )}
                  </View>
                </DrawerLayout.Content>
                <DrawerLayout.Tray
                  id="DrawerLayoutTray"
                  label="Splitscreen View Tray"
                  open={isSplitScreenViewOpen}
                  placement="end"
                  onDismiss={() => setSplitScreenViewOpen(false)}
                  data-testid="drawer-layout-tray"
                >
                  {ENV.split_screen_view && !ENV.isolated_view && threadParentEntryId && (
                    <View as="div" maxWidth={responsiveProps.viewPortWidth}>
                      <SplitScreenViewContainer
                        relativeEntryId={relativeEntryId}
                        removeDraftFromDiscussionCache={removeDraftFromDiscussionCache}
                        updateDraftCache={updateDraftCache}
                        discussionTopic={discussionTopicQuery.data.legacyNode}
                        discussionEntryId={threadParentEntryId}
                        open={isSplitScreenViewOpen}
                        RCEOpen={editorExpanded}
                        setRCEOpen={setEditorExpanded}
                        onClose={closeView}
                        onOpenSplitScreenView={openSplitScreenView}
                        goToTopic={goToTopic}
                        highlightEntryId={highlightEntryId}
                        setHighlightEntryId={setHighlightEntryId}
                      />
                    </View>
                  )}
                </DrawerLayout.Tray>
              </DrawerLayout>
            )
          }}
        />
      </DiscussionManagerUtilityContext.Provider>
    </SearchContext.Provider>
  )
}

DiscussionTopicManager.propTypes = {
  discussionTopicId: PropTypes.string.isRequired,
}

export default DiscussionTopicManager

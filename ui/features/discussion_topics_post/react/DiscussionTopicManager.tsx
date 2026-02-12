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

import {useQuery} from '@apollo/client'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {usePathTransform, whenPendoReady} from '@canvas/pendo'
import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Mask} from '@instructure/ui-overlays'
import {Responsive} from '@instructure/ui-responsive'
import {View} from '@instructure/ui-view'
import {captureException} from '@sentry/react'
import PropTypes from 'prop-types'
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import {flushSync} from 'react-dom'
import {DISCUSSION_QUERY} from '../graphql/Queries'
import {
  KeyboardShortcuts,
  useEventHandler,
  useKeyboardShortcuts,
} from './KeyboardShortcuts/useKeyboardShortcut'
import {LoadingSpinner} from './components/LoadingSpinner/LoadingSpinner'
import {NoResultsFound} from './components/NoResultsFound/NoResultsFound'
import {TranslationControls} from './components/TranslationControls/TranslationControls'
import {DiscussionTopicContainer} from './containers/DiscussionTopicContainer/DiscussionTopicContainer'
import {DiscussionTopicRepliesContainer} from './containers/DiscussionTopicRepliesContainer/DiscussionTopicRepliesContainer'
import DiscussionTopicToolbarContainer from './containers/DiscussionTopicToolbarContainer/DiscussionTopicToolbarContainer'
import {DiscussionTranslationModuleContainer} from './containers/DiscussionTranslationModuleContainer/DiscussionTranslationModuleContainer'
import {SplitScreenViewContainer} from './containers/SplitScreenViewContainer/SplitScreenViewContainer'
import StickyToolbarWrapper from './containers/StickyToolbarWrapper/StickyToolbarWrapper'
import useCreateDiscussionEntry from './hooks/useCreateDiscussionEntry'
import useHighlightStore from './hooks/useHighlightStore'
import useNavigateEntries from './hooks/useNavigateEntries'
import {useTranslationQueue} from './hooks/useTranslationQueue'
import {getCheckpointSubmission, getOptimisticResponse, responsiveQuerySizes} from './utils'
import {
  AllThreadsState,
  DiscussionManagerUtilityContext,
  HIGHLIGHT_TIMEOUT,
  REPLY_TO_ENTRY,
  REPLY_TO_TOPIC,
  SearchContext,
  isSpeedGraderInTopUrl,
} from './utils/constants'
import {PinnedContainer} from './components/PinnedContainer'
import {useTranslation} from './hooks/useTranslation'
import {PreferredLanguageModal} from './components/PreferredLanguageModal'
import {useTranslationStore} from './hooks/useTranslationStore'
import {ObserverContext} from './utils/ObserverContext'
import {useObservedTranslations} from './hooks/useObservedTranslations'
import {useTranslationAll} from './hooks/useTranslationAll'

const I18n = createI18nScope('discussion_topics_post')
const SEARCH_INPUT_SELECTOR = '#discussion-drawer-layout input[data-testid="search-filter"]'

// @ts-expect-error TS7006 (typescriptify)
const DiscussionTopicManager = props => {
  const {setOnSuccess} = useContext(AlertManagerContext)

  const [searchTerm, setSearchTerm] = useState('')
  const [filter, setFilter] = useState('all')
  const [unreadBefore, setUnreadBefore] = useState('')
  const [sort, setSort] = useState(null)
  // @ts-expect-error TS2339 (typescriptify)
  const [pageNumber, setPageNumber] = useState(ENV.current_page)
  const [searchPageNumber, setSearchPageNumber] = useState(0)
  const [allThreadsStatus, setAllThreadsStatus] = useState(AllThreadsState.None)
  const [expandedThreads, setExpandedThreads] = useState([])
  // This state is used to control the state of the topic RCE
  const [expandedTopicReply, setExpandedTopicReply] = useState(false)
  // @ts-expect-error TS2339 (typescriptify)
  const translationEnabled = useRef(ENV?.discussion_translation_available ?? false)
  // @ts-expect-error TS2339 (typescriptify)
  const translationLanguages = useRef(ENV?.discussion_translation_languages ?? [])
  const [showTranslationControl, setShowTranslationControl] = useState(false)
  // Start as null, populate when ready.
  const [translateTargetLanguage, setTranslateTargetLanguage] = useState(null)
  const [entryTranslatingSet, setEntryTranslatingSet] = useState(new Set())
  const [focusSelector, setFocusSelector] = useState('')

  const {enqueueTranslation, clearQueue} = useTranslationQueue()
  // @ts-expect-error TS2345 (typescriptify)
  const {translateAll} = useTranslationAll(enqueueTranslation)

  // @ts-expect-error TS7006 (typescriptify)
  const setEntryTranslating = useCallback((id, isTranslating) => {
    setEntryTranslatingSet(prevSet => {
      const newSet = new Set(prevSet)
      if (isTranslating) {
        newSet.add(id)
      } else {
        newSet.delete(id)
      }
      return newSet
    })
  }, [])

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
    discussionID: props.discussionTopicId,
    // @ts-expect-error TS2339 (typescriptify)
    perPage: ENV.per_page,
  }
  const [userSplitScreenPreference, setUserSplitScreenPreference] = useState(
    // @ts-expect-error TS2339 (typescriptify)
    (!isSpeedGraderInTopUrl && ENV.DISCUSSION?.preferences?.discussions_splitscreen_view) || false,
  )
  const goToTopic = () => {
    setSearchTerm('')
    closeView()
    setIsTopicHighlighted(true)
  }

  const setRootEntries = useHighlightStore(state => state.setRootEntries)
  const highlightNext = useHighlightStore(state => state.highlightNext)
  const highlightPrev = useHighlightStore(state => state.highlightPrev)
  const addRootEntryId = useHighlightStore(state => state.addRootEntry)

  // Split_screen parent id
  const [threadParentEntryId, setThreadParentEntryId] = useState(
    // @ts-expect-error TS2339 (typescriptify)
    ENV.discussions_deep_link?.parent_id,
  )
  const [replyFromId, setReplyFromId] = useState(null)

  // split screen view
  const [isSplitScreenViewOpen, setSplitScreenViewOpen] = useState(
    !isSpeedGraderInTopUrl &&
      // @ts-expect-error TS2339 (typescriptify)
      ENV.DISCUSSION?.preferences?.discussions_splitscreen_view &&
      // @ts-expect-error TS2339 (typescriptify)
      !!(ENV.discussions_deep_link?.parent_id
        ? // @ts-expect-error TS2339 (typescriptify)
          ENV.discussions_deep_link?.parent_id
        : // @ts-expect-error TS2339 (typescriptify)
          ENV.discussions_deep_link?.entry_id),
  )
  const [isSplitScreenViewOverlayed, setSplitScreenViewOverlayed] = useState(false)
  const [editorExpanded, setEditorExpanded] = useState(false)

  // Highlight State
  const [isTopicHighlighted, setIsTopicHighlighted] = useState(false)
  // @ts-expect-error TS2339 (typescriptify)
  const [highlightEntryId, setHighlightEntryId] = useState(ENV.discussions_deep_link?.entry_id)
  const [relativeEntryId, setRelativeEntryId] = useState(null)

  const [replyToTopicSubmission, setReplyToTopicSubmission] = useState({})
  const [replyToEntrySubmission, setReplyToEntrySubmission] = useState({})

  const [isGradedDiscussion, setIsGradedDiscussion] = useState(false)

  // The DrawTray will cause the DiscussionEdit to mount first when it starts transitioning open, then un-mount and remount when it finishes opening
  const [isTrayFinishedOpening, setIsTrayFinishedOpening] = useState(false)

  const usedThreadingToolbarChildRef = useRef(null)

  const previousSearchTerm = useRef(null)

  // @ts-expect-error TS2339 (typescriptify)
  const [isSummaryEnabled, setIsSummaryEnabled] = useState(ENV.discussion_summary_enabled || false)

  const discussionManagerUtilities = {
    replyFromId,
    setReplyFromId,
    userSplitScreenPreference,
    setUserSplitScreenPreference,
    highlightEntryId,
    setHighlightEntryId,
    setPageNumber,
    expandedThreads,
    setExpandedThreads,
    focusSelector,
    setFocusSelector,
    setIsGradedDiscussion,
    isGradedDiscussion,
    usedThreadingToolbarChildRef,
    translationEnabled,
    translationLanguages,
    showTranslationControl,
    setShowTranslationControl,
    translateTargetLanguage,
    setTranslateTargetLanguage,
    entryTranslatingSet,
    setEntryTranslating,
    enqueueTranslation,
    clearQueue,
    isSummaryEnabled,
    setIsSummaryEnabled,
  }

  const urlParams = new URLSearchParams(window.location.search)
  const isPersistEnabled = urlParams.get('persist') === '1'

  // Reset page number to 0 when inactive
  useEffect(() => {
    if (searchTerm && pageNumber !== 0) {
      setPageNumber(0)
    } else if (!searchTerm && searchPageNumber !== 0) {
      setSearchPageNumber(0)
    }
  }, [pageNumber, searchPageNumber, searchTerm])

  useEffect(() => {
    if (isTopicHighlighted && !isPersistEnabled) {
      setTimeout(() => {
        setIsTopicHighlighted(false)
      }, HIGHLIGHT_TIMEOUT)
    }
  }, [isPersistEnabled, isTopicHighlighted])

  /**
   * Opens a split-screen view for a discussion entry.
   *
   * @param {number} discussionEntryId - The ID of the discussion entry that will be displayed.
   *                                     This ID represents the ThreadParentEntryId and is the root entry in the thread.
   * @param {boolean} withRCE - Controls whether the Rich Content Editor (RCE) will be open or not.
   * @param {number|null} relativeId - Optional. Used primarily when opening from a search context.
   *                                   This parameter determines the starting point for querying additional entries.
   *                                   For example, if opening entry 120 out of 200, and when clicking next,
   *                                   the function needs to know it's at entry 120 to fetch entries 121-140.
   *                                   Defaults to `null` if not specified.
   */
  // @ts-expect-error TS7006 (typescriptify)
  const openSplitScreenView = (discussionEntryId, withRCE, relativeId = null) => {
    setThreadParentEntryId(discussionEntryId)
    setSplitScreenViewOpen(true)
    setEditorExpanded(withRCE)
    setRelativeEntryId(relativeId)
  }

  const closeView = () => {
    flushSync(() => {
      setIsTrayFinishedOpening(false)
      setSplitScreenViewOpen(false)
    })

    // @ts-expect-error TS2339 (typescriptify)
    usedThreadingToolbarChildRef?.current?.focus()
    usedThreadingToolbarChildRef.current = null
  }

  const variables = {
    discussionID: props.discussionTopicId,
    // @ts-expect-error TS2339 (typescriptify)
    perPage: ENV.per_page,
    // @ts-expect-error TS2339,TS2769 (typescriptify)
    page: searchTerm ? btoa(searchPageNumber * ENV.per_page) : btoa(pageNumber * ENV.per_page),
    searchTerm,
    rootEntries: !searchTerm && filter === 'all',
    filter,
    unreadBefore,
  }

  // Unread and unreadBefore both useState and trigger useQuery. We need to wait until both are set.
  // Also when switching from unread the same issue causes 2 queries when unreadBefore switches to '',
  // but unreadBefore only applies to unread filter. So we dont need the extra query.
  const waitForUnreadFilter =
    (filter === 'unread' && !unreadBefore) || (filter !== 'unread' && unreadBefore)

  const discussionTopicQuery = useQuery(DISCUSSION_QUERY, {
    variables,
    fetchPolicy: searchTerm ? 'network-only' : 'cache-and-network',
    // @ts-expect-error TS2322 (typescriptify)
    skip: waitForUnreadFilter,
  })

  const isAnnouncement = useMemo(
    () => discussionTopicQuery.data?.legacyNode?.isAnnouncement,
    [discussionTopicQuery.data],
  )

  useTranslation()

  usePathTransform(whenPendoReady, 'discussion_topics', 'announcements', isAnnouncement)
  useEventHandler(KeyboardShortcuts.ON_PREV_REPLY, () =>
    highlightPrev(userSplitScreenPreference, isSplitScreenViewOpen),
  )
  useEventHandler(KeyboardShortcuts.ON_NEXT_REPLY, () =>
    highlightNext(userSplitScreenPreference, isSplitScreenViewOpen),
  )

  useEffect(() => {
    if (
      setRootEntries &&
      discussionTopicQuery.data?.legacyNode?.discussionEntriesConnection?.nodes?.length > 0
    ) {
      setRootEntries(
        discussionTopicQuery.data?.legacyNode?.discussionEntriesConnection?.nodes
          // @ts-expect-error TS7031 (typescriptify)
          .filter(({deleted, subentriesCount}) => !deleted || subentriesCount > 0)
          // @ts-expect-error TS7031 (typescriptify)
          .map(({_id}) => _id),
      )
    }
  }, [setRootEntries, discussionTopicQuery.data?.legacyNode?.discussionEntriesConnection?.nodes])

  const [firstRequest, setFirstRequest] = useState(true)
  useEffect(() => {
    if (!discussionTopicQuery.data || !firstRequest) return
    setFirstRequest(false)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [discussionTopicQuery])

  // announce search entry count
  useEffect(() => {
    if (searchTerm && discussionTopicQuery.data) {
      const searchEntryCount = discussionTopicQuery.data.legacyNode?.searchEntryCount || 0
      setTimeout(() => {
        const inputElement = document.querySelector(SEARCH_INPUT_SELECTOR)
        // @ts-expect-error TS2339 (typescriptify)
        inputElement?.focus()
        const message = I18n.t(
          {
            one: '1 result found for %{searchTerm}',
            other: '%{count} results found for %{searchTerm}',
            zero: 'No results found for %{searchTerm}',
          },
          {
            count: searchEntryCount,
            searchTerm: searchTerm,
          },
        )
        setOnSuccess(message, true)
      }, 500)
    }
  }, [searchTerm, discussionTopicQuery, setOnSuccess])

  useEffect(() => {
    if (previousSearchTerm.current && !searchTerm) {
      setTimeout(() => {
        const inputElement = document.querySelector(SEARCH_INPUT_SELECTOR)
        // @ts-expect-error TS2339 (typescriptify)
        inputElement?.focus()
        setOnSuccess(I18n.t('Search cleared. No filters applied.'), true)
      }, 600)
    }
    // @ts-expect-error TS2322 (typescriptify)
    previousSearchTerm.current = searchTerm
  }, [searchTerm, setOnSuccess])

  // Unread filter
  // This introduces a double query for DISCUSSION_QUERY when filter changes
  useEffect(() => {
    if (filter === 'unread' && !unreadBefore) {
      setUnreadBefore(new Date(Date.now()).toISOString())
    } else if (filter !== 'unread') {
      setUnreadBefore('')
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (firstRequest && ENV.current_page !== 0) return
    setPageNumber(0)
    setSearchPageNumber(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filter, unreadBefore])

  useEffect(() => {
    if (highlightEntryId && !isPersistEnabled) {
      const timeoutId = setTimeout(() => {
        setHighlightEntryId(null)
      }, HIGHLIGHT_TIMEOUT)

      return () => {
        clearTimeout(timeoutId)
      }
    }
  }, [highlightEntryId, isPersistEnabled])

  useNavigateEntries({
    highlightEntryId,
    // @ts-expect-error TS2322 (typescriptify)
    setHighlightEntryId,
    // @ts-expect-error TS2322 (typescriptify)
    setPageNumber,
    expandedThreads,
    // @ts-expect-error TS2322 (typescriptify)
    setExpandedThreads,
    // @ts-expect-error TS2322 (typescriptify)
    setFocusSelector,
    discussionID: props.discussionTopicId,
    // @ts-expect-error TS2339 (typescriptify)
    perPage: ENV.per_page,
    // @ts-expect-error TS2322 (typescriptify)
    sort,
  })

  useEffect(() => {
    setIsGradedDiscussion(!!discussionTopicQuery?.data?.legacyNode?.assignment)
  }, [discussionTopicQuery?.data?.legacyNode?.assignment])

  // @ts-expect-error TS7006 (typescriptify)
  const getSubmissionObject = (submissionsArray, submissionTag) => {
    // @ts-expect-error TS7006 (typescriptify)
    return submissionsArray.find(node => node.subAssignmentTag === submissionTag) || {}
  }
  // set initial checkpoint submission objects
  useEffect(() => {
    setTimeout(() => {
      const submissionsArray =
        discussionTopicQuery?.data?.legacyNode?.assignment?.mySubAssignmentSubmissionsConnection
          ?.nodes || []
      setReplyToTopicSubmission(getSubmissionObject(submissionsArray, REPLY_TO_TOPIC))
      setReplyToEntrySubmission(getSubmissionObject(submissionsArray, REPLY_TO_ENTRY))
    }, 0)
  }, [discussionTopicQuery])

  // @ts-expect-error TS7006 (typescriptify)
  const updateCache = (cache, result) => {
    try {
      const options = {
        query: DISCUSSION_QUERY,
        variables: {...variables},
      }
      const newDiscussionEntry = result.data.createDiscussionEntry.discussionEntry
      const currentDiscussion = JSON.parse(JSON.stringify(cache.readQuery(options)))
      const isInitialPostRequired = currentDiscussion.legacyNode.initialPostRequiredForCurrentUser

      // if the current user hasn't made the required inital post, then this entry will be it.
      // In that case, we are required to do a page refresh to get all the entries (implemented in onComplete, as updateCache is fired twice,
      // once for the optimistic response, and once for the real one...)
      // thus we basically want to not do this if that contains updateCache logic.
      // Discussion.initialPostRequiredForCurrentUser is based on user and topic so if the user meets this requirement, then
      // this doesnt run and caching resumes as normal.
      if (!isInitialPostRequired && currentDiscussion && newDiscussionEntry) {
        // if we have a new entry update the counts, because we are about to add to the cache (something useMutation dont do, that useQuery does)
        currentDiscussion.legacyNode.entryCounts.repliesCount += 1
        // add the new entry to the current entries in the cache
        if (currentDiscussion.legacyNode.participant.sortOrder === 'desc') {
          currentDiscussion.legacyNode.discussionEntriesConnection.nodes.unshift(newDiscussionEntry)
          addRootEntryId(newDiscussionEntry._id, 'first')
        } else {
          currentDiscussion.legacyNode.discussionEntriesConnection.nodes.push(newDiscussionEntry)
          addRootEntryId(newDiscussionEntry._id, 'last')
        }
        cache.writeQuery({...options, data: currentDiscussion})
      }

      if (result.data.createDiscussionEntry.mySubAssignmentSubmissions?.length > 0) {
        const submissionsArray = result.data.createDiscussionEntry.mySubAssignmentSubmissions
        currentDiscussion.legacyNode.assignment.mySubAssignmentSubmissionsConnection.nodes =
          submissionsArray
        cache.writeQuery({...options, data: currentDiscussion})
      }
    } catch (e) {
      discussionTopicQuery.refetch(variables)
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  const onEntryCreationCompletion = (data, success) => {
    if (success) {
      setHighlightEntryId(data.createDiscussionEntry.discussionEntry._id)
      setReplyToTopicSubmission(getCheckpointSubmission(data, REPLY_TO_TOPIC))
      setReplyToEntrySubmission(getCheckpointSubmission(data, REPLY_TO_ENTRY))

      if (sort === 'asc') {
        setPageNumber(discussionTopicQuery.data.legacyNode.entriesTotalPages - 1)
      }
      if (
        discussionTopicQuery.data.legacyNode.availableForUser &&
        discussionTopicQuery.data.legacyNode.initialPostRequiredForCurrentUser
      ) {
        discussionTopicQuery.refetch(variables)
      }
      setExpandedTopicReply(false)
    }
  }

  // Used when replying to the Topic directly
  const {createDiscussionEntry, isSubmitting} = useCreateDiscussionEntry(
    onEntryCreationCompletion,
    updateCache,
  )

  const observerContextData = useObservedTranslations(enqueueTranslation)

  if (discussionTopicQuery.loading || waitForUnreadFilter) {
    return <LoadingSpinner />
  }

  if (discussionTopicQuery.error || !discussionTopicQuery?.data?.legacyNode) {
    captureException(
      new Error(`Error received from discussionTopicQuery: ${discussionTopicQuery.error}`),
    )

    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Discussion Topic initial query error')}
        errorCategory={I18n.t('Discussion Topic Post Error Page')}
        errorMessage={discussionTopicQuery.error}
      />
    )
  }

  return (
    // @ts-expect-error TS2322 (typescriptify)
    <SearchContext.Provider value={searchContext}>
      <ObserverContext.Provider value={observerContextData}>
        {/* @ts-expect-error TS2322 (typescriptify) */}
        <DiscussionManagerUtilityContext.Provider value={discussionManagerUtilities}>
          <Responsive
            match="media"
            // @ts-expect-error TS2769 (typescriptify)
            query={responsiveQuerySizes({mobile: true, desktop: true})}
            props={{
              mobile: {
                viewPortWidth: '100vw',
                padding: 'medium x-small 0',
                height: '100vh',
              },
              desktop: {
                viewPortWidth: '480px',
                padding: 'medium medium 0 small',
                height: `calc(100vh - ${props.navbarHeight}px)`,
              },
            }}
            render={responsiveProps => {
              return (
                // @ts-expect-error TS18049 (typescriptify)
                <View height={responsiveProps.height} display="block">
                  <DrawerLayout
                    onOverlayTrayChange={isOverlayed => {
                      setSplitScreenViewOverlayed(isOverlayed)
                    }}
                  >
                    {isSplitScreenViewOverlayed && isSplitScreenViewOpen && (
                      <Mask onClick={() => closeView()} />
                    )}
                    <DrawerLayout.Content
                      // please keep in mind that this id is used for determining
                      // the width of StickyToolbarWrapper upon window resize
                      id="discussion-drawer-layout"
                      label="Splitscreen View Content"
                    >
                      <View
                        display="block"
                        // @ts-expect-error TS18049 (typescriptify)
                        padding={responsiveProps.padding}
                        id="module_sequence_footer_container"
                      >
                        {ENV?.FEATURES?.discussion_checkpoints && isSpeedGraderInTopUrl ? (
                          <StickyToolbarWrapper>
                            <DiscussionTopicToolbarContainer
                              discussionTopic={discussionTopicQuery.data.legacyNode}
                              setUserSplitScreenPreference={setUserSplitScreenPreference}
                              userSplitScreenPreference={userSplitScreenPreference}
                              closeView={closeView}
                              breakpoints={props.breakpoints}
                            />
                          </StickyToolbarWrapper>
                        ) : (
                          <DiscussionTopicToolbarContainer
                            discussionTopic={discussionTopicQuery.data.legacyNode}
                            setUserSplitScreenPreference={setUserSplitScreenPreference}
                            userSplitScreenPreference={userSplitScreenPreference}
                            closeView={closeView}
                            breakpoints={props.breakpoints}
                          />
                        )}
                        {/* @ts-expect-error TS2339 (typescriptify) */}
                        {showTranslationControl && ENV.ai_translation_improvements && (
                          <DiscussionTranslationModuleContainer
                            isAnnouncement={discussionTopicQuery.data.legacyNode?.isAnnouncement}
                          />
                        )}
                        {/* @ts-expect-error TS2339 (typescriptify) */}
                        {showTranslationControl && !ENV.ai_translation_improvements && (
                          // @ts-expect-error TS2322 (typescriptify)
                          <TranslationControls onSetSelectedLanguage={translateAll} />
                        )}
                        <DiscussionTopicContainer
                          discussionTopic={discussionTopicQuery.data.legacyNode}
                          expandedTopicReply={expandedTopicReply}
                          setExpandedTopicReply={setExpandedTopicReply}
                          // @ts-expect-error TS7006 (typescriptify)
                          createDiscussionEntry={(message, file, isAnonymousAuthor) => {
                            createDiscussionEntry({
                              variables: {
                                discussionTopicId: ENV.discussion_topic_id,
                                message,
                                fileId: file?._id,
                                isAnonymousAuthor,
                              },
                              optimisticResponse: getOptimisticResponse({
                                message,
                                attachment: file,
                                isAnonymous:
                                  isAnonymousAuthor &&
                                  !!discussionTopicQuery.data.legacyNode.anonymousState &&
                                  discussionTopicQuery.data.legacyNode.canReplyAnonymously,
                              }),
                            })
                            setHighlightEntryId('DISCUSSION_ENTRY_PLACEHOLDER')
                          }}
                          isHighlighted={isTopicHighlighted}
                          replyToTopicSubmission={replyToTopicSubmission}
                          replyToEntrySubmission={replyToEntrySubmission}
                          // @ts-expect-error TS2339 (typescriptify)
                          isSummaryEnabled={ENV.user_can_summarize && isSummaryEnabled}
                          setIsSummaryEnabled={setIsSummaryEnabled}
                          isSubmitting={isSubmitting}
                        />

                        {ENV.discussion_pin_post && (
                          <PinnedContainer
                            entries={discussionTopicQuery?.data?.legacyNode?.pinnedEntries || []}
                            topic={discussionTopicQuery.data.legacyNode}
                            breakpoints={props.breakpoints}
                          />
                        )}
                        {discussionTopicQuery.data.legacyNode.discussionEntriesConnection.nodes
                          .length === 0 &&
                        (searchTerm || filter === 'unread') ? (
                          <NoResultsFound />
                        ) : (
                          discussionTopicQuery.data.legacyNode.availableForUser && (
                            <DiscussionTopicRepliesContainer
                              discussionTopic={discussionTopicQuery.data.legacyNode}
                              onOpenSplitView={(
                                discussionEntryId,
                                withRCE,
                                relativeId,
                                highlightId,
                              ) => {
                                setHighlightEntryId(highlightId)
                                openSplitScreenView(discussionEntryId, withRCE, relativeId)
                              }}
                              goToTopic={goToTopic}
                              highlightEntryId={highlightEntryId}
                              setHighlightEntryId={setHighlightEntryId}
                              isSearchResults={!!searchTerm}
                              userSplitScreenPreference={userSplitScreenPreference}
                              refetchDiscussionEntries={discussionTopicQuery.refetch}
                            />
                          )
                        )}
                      </View>
                    </DrawerLayout.Content>
                    <DrawerLayout.Tray
                      id="DrawerLayoutTray"
                      label="Splitscreen View Tray"
                      open={isSplitScreenViewOpen}
                      placement="end"
                      onEntered={() => setIsTrayFinishedOpening(true)}
                      onDismiss={() => closeView()}
                      data-testid="drawer-layout-tray"
                      shouldCloseOnDocumentClick={false}
                    >
                      {threadParentEntryId && (
                        // @ts-expect-error TS18049 (typescriptify)
                        <View as="div" maxWidth={responsiveProps.viewPortWidth}>
                          <SplitScreenViewContainer
                            relativeEntryId={relativeEntryId}
                            discussionTopic={discussionTopicQuery.data.legacyNode}
                            discussionEntryId={threadParentEntryId}
                            // @ts-expect-error TS2322 (typescriptify)
                            open={isSplitScreenViewOpen}
                            RCEOpen={editorExpanded}
                            setRCEOpen={setEditorExpanded}
                            onClose={closeView}
                            onOpenSplitScreenView={openSplitScreenView}
                            goToTopic={goToTopic}
                            highlightEntryId={highlightEntryId}
                            setHighlightEntryId={setHighlightEntryId}
                            isTrayFinishedOpening={isTrayFinishedOpening}
                            setReplyToTopicSubmission={setReplyToTopicSubmission}
                            setReplyToEntrySubmission={setReplyToEntrySubmission}
                          />
                        </View>
                      )}
                    </DrawerLayout.Tray>
                  </DrawerLayout>
                </View>
              )
            }}
          />
          {/* @ts-expect-error TS2322 (typescriptify) */}
          <PreferredLanguageModal discussionTopicId={ENV.discussion_topic_id} />
        </DiscussionManagerUtilityContext.Provider>
      </ObserverContext.Provider>
    </SearchContext.Provider>
  )
}

DiscussionTopicManager.propTypes = {
  discussionTopicId: PropTypes.string.isRequired,
  breakpoints: breakpointsShape,
  navbarHeight: PropTypes.number,
}

export default WithBreakpoints(DiscussionTopicManager)

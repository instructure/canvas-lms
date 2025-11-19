/* eslint-disable react/prop-types */
/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconCommentLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {useCallback, useEffect, useMemo, useState} from 'react'
import {useQuery} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  SpeedGraderLegacy_CommentBankItems,
  SpeedGraderLegacy_CommentBankItemsCount,
} from './graphql/queries'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import {CommentLibraryTray} from './components/CommentLibraryTray'
import {
  SpeedGraderLegacy_CommentBankItemsCountQuery,
  SpeedGraderLegacy_CommentBankItemsQuery,
} from '@canvas/graphql/codegen/graphql'
import {useDebounce} from 'use-debounce'
import Suggestions from './Suggestions'

const I18n = createI18nScope('CommentLibrary')

export type CommentLibraryContentProps = {
  comment: string
  userId: string
  courseId: string
  setFocusToTextArea: () => void
  setComment: (content: string) => void
}

export const CommentLibraryContent: React.FC<CommentLibraryContentProps> = ({
  comment,
  courseId,
  userId,
  setFocusToTextArea,
  setComment,
}) => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)

  const [isSearchEnabled, setIsSearchEnabled] = useState(true)
  const [showSuggestionResults, setShowSuggestionResults] = useState(true)
  const [suggestionsWhenTypingEnabled, setSuggestionsWhenTypingEnabled] = useState(
    ENV.comment_library_suggestions_enabled,
  )

  const {data, loading} = useQuery<SpeedGraderLegacy_CommentBankItemsCountQuery>(
    SpeedGraderLegacy_CommentBankItemsCount,
    {variables: {userId}},
  )
  useEffect(() => {
    if (comment.length === 0) setIsSearchEnabled(true)
    setShowSuggestionResults(true)
  }, [comment])

  const [searchTerm, state] = useDebounce(comment.replace(/<[^>]*>/g, ''), 750)

  const {data: suggestedCommentsData} = useQuery<SpeedGraderLegacy_CommentBankItemsQuery>(
    SpeedGraderLegacy_CommentBankItems,
    {
      variables: {userId, query: searchTerm, first: 5},
      skip: searchTerm.length < 3 || !suggestionsWhenTypingEnabled || !isSearchEnabled,
    },
  )

  const suggestedComments = useMemo(() => {
    if (
      suggestedCommentsData?.legacyNode &&
      'commentBankItemsConnection' in suggestedCommentsData.legacyNode
    ) {
      const conn = suggestedCommentsData.legacyNode.commentBankItemsConnection
      return conn?.nodes?.filter(it => it !== null) ?? []
    }
    return []
  }, [suggestedCommentsData])

  const showResults =
    // comment libary suggestions are enabled
    suggestionsWhenTypingEnabled &&
    !state.isPending() &&
    // search is enabled (there was no inserted comment library item since the textarea was
    // cleared)
    isSearchEnabled &&
    // suggested items are not being loaded an there is any suggested comment item
    suggestedComments.length > 0 &&
    // suggestions results are not shown on purpose (user closed popover)
    showSuggestionResults

  const commentBankItemsCount = useMemo(() => {
    let count = 0
    if (data?.legacyNode && 'commentBankItemsConnection' in data.legacyNode) {
      count = data.legacyNode.commentBankItemsConnection?.pageInfo.totalCount ?? 0
    }
    return count > 99 ? '99+' : String(count)
  }, [data])

  const setCommentFromLibrary = useCallback(
    (value: string) => {
      setIsTrayOpen(false)
      setShowSuggestionResults(false)
      setIsSearchEnabled(false)
      setComment(value)
      setTimeout(() => {
        setFocusToTextArea()
      }, 0)
    },
    [setComment, setFocusToTextArea],
  )

  // Show loading state if count is loading for more than 500ms
  if (loading || !data) {
    return (
      <View as="div" textAlign="end">
        <Spinner size="x-small" renderTitle={() => I18n.t('Loading comment library')} delay={500} />
      </View>
    )
  }

  let commentLibraryButton = (
    <Button
      withBackground={false}
      color="primary"
      onClick={() => setIsTrayOpen(true)}
      data-testid="comment-library-button"
      themeOverride={{borderWidth: '0'}}
      renderIcon={<IconCommentLine />}
      size="small"
    >
      <ScreenReaderContent>{I18n.t('Open Comment Library')}</ScreenReaderContent>
      <PresentationContent data-testid="comment-library-count">
        {commentBankItemsCount}
      </PresentationContent>
    </Button>
  )

  if (!suggestionsWhenTypingEnabled) {
    commentLibraryButton = (
      <Tooltip renderTip={I18n.t('Comment Library (Suggestions Disabled)')}>
        {commentLibraryButton}
      </Tooltip>
    )
  }

  return (
    <>
      <Flex direction="row-reverse" padding="medium 0 xx-small small">
        <Flex.Item>
          <View display="flex" />
          <View as="div" padding="0 0 0 x-small" display="flex">
            {commentLibraryButton}
            <Suggestions
              searchResults={suggestedComments}
              setComment={setCommentFromLibrary}
              onClose={() => {
                setShowSuggestionResults(false)
                setTimeout(() => {
                  setFocusToTextArea()
                }, 0)
              }}
              showResults={showResults}
            />
          </View>
        </Flex.Item>
      </Flex>
      <CommentLibraryTray
        userId={userId}
        courseId={courseId}
        isOpen={isTrayOpen}
        onDismiss={() => setIsTrayOpen(false)}
        setCommentFromLibrary={setCommentFromLibrary}
        suggestionsWhenTypingEnabled={suggestionsWhenTypingEnabled}
        setSuggestionsWhenTypingEnabled={setSuggestionsWhenTypingEnabled}
      />
    </>
  )
}

const client = createClient()

type CommentLibraryProps = {
  comment: string
  userId: string
  courseId: string
  setFocusToTextArea: () => void
  setComment: (content: string) => void
}

export const CommentLibrary: React.FC<CommentLibraryProps> = props => (
  <ApolloProvider client={client}>
    <CommentLibraryContent {...props} />
  </ApolloProvider>
)

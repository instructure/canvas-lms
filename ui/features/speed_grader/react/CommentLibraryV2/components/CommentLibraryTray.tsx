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

import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useQuery, NetworkStatus} from '@apollo/client'
import {Tray} from '@instructure/ui-tray'
import {Text} from '@instructure/ui-text'
import {Button, CloseButton} from '@instructure/ui-buttons'
import CommentRouterView from './CommentRouterView'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {SpeedGraderLegacy_CommentBankItems} from '../graphql/queries'
import {SpeedGraderLegacy_CommentBankItemsQuery} from '@canvas/graphql/codegen/graphql'
import {CreateCommentSection} from './CreateCommentSection'
import {SuggestionsEnabledToggleSection} from './SuggestionsEnabledToggleSection'

const I18n = createI18nScope('CommentLibrary')

export type CommentLibraryTrayProps = {
  userId: string
  courseId: string
  isOpen: boolean
  onDismiss: () => void
  setCommentFromLibrary: (value: string) => void
  suggestionsWhenTypingEnabled: boolean
  setSuggestionsWhenTypingEnabled: (value: boolean) => void
}

export const CommentLibraryTray: React.FC<CommentLibraryTrayProps> = ({
  courseId,
  userId,
  isOpen,
  onDismiss,
  setCommentFromLibrary,
  suggestionsWhenTypingEnabled,
  setSuggestionsWhenTypingEnabled,
}) => {
  const queryVariables = useMemo(
    () => ({userId, courseId, first: 20, after: ''}),
    [userId, courseId],
  )
  const {data, error, fetchMore, networkStatus} = useQuery<SpeedGraderLegacy_CommentBankItemsQuery>(
    SpeedGraderLegacy_CommentBankItems,
    {
      variables: queryVariables,
      notifyOnNetworkStatusChange: true,
      skip: !isOpen,
    },
  )

  const isInitialLoad = networkStatus === NetworkStatus.loading
  const isFetchingMore = networkStatus === NetworkStatus.fetchMore

  const {comments, hasNextPage, endCursor} = useMemo(() => {
    if (data?.legacyNode && 'commentBankItemsConnection' in data.legacyNode) {
      const conn = data.legacyNode.commentBankItemsConnection
      return {
        comments: conn?.nodes?.filter(it => it !== null) ?? [],
        hasNextPage: conn?.pageInfo.hasNextPage ?? false,
        endCursor: conn?.pageInfo.endCursor ?? '',
      }
    }
    return {comments: [], hasNextPage: false, endCursor: ''}
  }, [data])

  useEffect(() => {
    if (error) showFlashAlert({message: I18n.t('Error loading comment library'), type: 'error'})
  }, [error])

  let content = null
  if (isInitialLoad) {
    content = (
      <Flex justifyItems="center" height="100%">
        <Spinner size="small" renderTitle={I18n.t('Loading comment library')} />
      </Flex>
    )
  } else {
    content = (
      <View as="div" data-testid="library-comment-area">
        {comments.map((it: {_id: string; comment: string}, index: number) => (
          <CommentRouterView
            key={it._id}
            onClick={() => setCommentFromLibrary(it.comment)}
            comment={it.comment}
            index={index}
            id={it._id}
          />
        ))}
        {hasNextPage && (
          <Flex justifyItems="center" padding="small 0">
            <Flex.Item>
              <Button
                data-testid="load-more-comments-button"
                onClick={() => {
                  fetchMore({variables: {...queryVariables, after: endCursor}})
                }}
                disabled={isFetchingMore}
              >
                {isFetchingMore ? I18n.t('Loading...') : I18n.t('Load more comments')}
              </Button>
            </Flex.Item>
          </Flex>
        )}
      </View>
    )
  }

  return (
    <Tray
      data-testid="comment-library-tray"
      size="regular"
      label={I18n.t('Comment Library')}
      placement="end"
      open={isOpen}
      onDismiss={onDismiss}
    >
      <Flex as="div" direction="column" height="100vh">
        <Flex.Item as="div" padding="small">
          <Flex as="div" direction="row" alignItems="start">
            <div style={{height: '100%', alignContent: 'center', flex: 1}}>
              <Text weight="bold" size="medium" as="h2">
                {I18n.t('Manage Comment Library')}
              </Text>
            </div>
            {onDismiss && (
              <Flex.Item as="div">
                <CloseButton
                  screenReaderLabel={I18n.t('Close')}
                  onClick={onDismiss}
                  data-testid="tray-close-button"
                />
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>

        <Flex.Item as="div" shouldGrow shouldShrink padding="small">
          <SuggestionsEnabledToggleSection
            checked={suggestionsWhenTypingEnabled}
            onChange={setSuggestionsWhenTypingEnabled}
          />
          {content}
        </Flex.Item>
        <Flex.Item as="div" padding="small">
          <CreateCommentSection courseId={courseId} />
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

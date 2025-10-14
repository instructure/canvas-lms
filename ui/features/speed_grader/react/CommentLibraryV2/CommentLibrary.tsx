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
import {useMemo, useState} from 'react'
import {useQuery} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SpeedGrader_CommentBankItemsCount} from './graphql/queries'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import {SpeedGrader_CommentBankItemsCountQuery} from '@canvas/graphql/codegen/graphql'

const I18n = createI18nScope('CommentLibrary')

export type CommentLibraryContentProps = {
  userId: string
}

export const CommentLibraryContent: React.FC<CommentLibraryContentProps> = ({userId}) => {
  const [suggestionsWhenTypingEnabled] = useState(ENV.comment_library_suggestions_enabled)

  const {data, loading} = useQuery<SpeedGrader_CommentBankItemsCountQuery>(
    SpeedGrader_CommentBankItemsCount,
    {variables: {userId}},
  )

  const commentBankItemsCount = useMemo(() => {
    let count = 0
    if (data?.legacyNode && 'commentBankItemsConnection' in data.legacyNode) {
      count = data.legacyNode.commentBankItemsConnection?.pageInfo.totalCount ?? 0
    }
    return count > 99 ? '99+' : String(count)
  }, [data])

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
    <Flex direction="row-reverse" padding="medium 0 xx-small small">
      <Flex.Item>
        <View display="flex" />
        <View as="div" padding="0 0 0 x-small" display="flex">
          {commentLibraryButton}
        </View>
      </Flex.Item>
    </Flex>
  )
}

const client = createClient()

type CommentLibraryProps = {
  userId: string
}

export const CommentLibrary: React.FC<CommentLibraryProps> = props => (
  <ApolloProvider client={client}>
    <CommentLibraryContent {...props} />
  </ApolloProvider>
)

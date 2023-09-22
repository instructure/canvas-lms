/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import formatMessage from '../../../../format-message'
import {getIcon} from '../../shared/linkUtils'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

type ContextType = 'course' | 'group'

export type CollectionType =
  | 'wikiPages'
  | 'assignments'
  | 'quizzes'
  | 'announcements'
  | 'discussions'
  | 'modules'

type NoResultsProps = {
  contextType: ContextType
  contextId: string
  collectionType: CollectionType
  isSearchResult: boolean
}

export function buildUrl(
  contextType: ContextType,
  contextId: string,
  collectionType: CollectionType
): string {
  const typeMap: Partial<Record<CollectionType, string>> = {
    wikiPages: 'pages',
    discussions: 'discussion_topics',
  }
  return `/${contextType}s/${contextId}/${typeMap[collectionType] ?? collectionType}`
}

export function getMessage(collectionType: CollectionType, isSearchResult: boolean): string {
  switch (collectionType) {
    case 'wikiPages':
      return isSearchResult
        ? formatMessage('No pages found.')
        : formatMessage('No pages created yet.')
    case 'assignments':
      return isSearchResult
        ? formatMessage('No assignments found.')
        : formatMessage('No assignments created yet.')
    case 'quizzes':
      return isSearchResult
        ? formatMessage('No quizzes found.')
        : formatMessage('No quizzes created yet.')
    case 'announcements':
      return isSearchResult
        ? formatMessage('No announcements found.')
        : formatMessage('No announcements created yet.')
    case 'discussions':
      return isSearchResult
        ? formatMessage('No discussions found.')
        : formatMessage('No discussions created yet.')
    case 'modules':
      return isSearchResult
        ? formatMessage('No modules found.')
        : formatMessage('No modules created yet.')
  }
}

export const NoResults = ({
  contextType,
  contextId,
  collectionType,
  isSearchResult,
}: NoResultsProps) => {
  const Icon = getIcon(collectionType)
  return (
    <View padding="xx-large">
      <Flex justifyItems="center" alignItems="center" direction="column">
        <FlexItem>
          <Icon size="large" color="secondary" padding="large" />
        </FlexItem>
        <FlexItem margin="small 0 0">
          <Text>{getMessage(collectionType, isSearchResult)}</Text>
        </FlexItem>
        {!isSearchResult && (
          <FlexItem>
            <Link
              href={buildUrl(contextType, contextId, collectionType)}
              // @ts-expect-error
              target="_blank"
            >
              {formatMessage('Add one!')}
            </Link>
          </FlexItem>
        )}
      </Flex>
    </View>
  )
}

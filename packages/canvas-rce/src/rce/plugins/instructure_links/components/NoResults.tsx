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
        <Flex.Item>
          {/* @ts-expect-error  not sure padding is even allowed on Icons */}
          <Icon size="large" color="secondary" padding="large" />
        </Flex.Item>
        <Flex.Item margin="small 0 0">
          <Text>{getMessage(collectionType, isSearchResult)}</Text>
        </Flex.Item>
        {!isSearchResult && (
          <Flex.Item>
            <Link href={buildUrl(contextType, contextId, collectionType)} target="_blank">
              {formatMessage('Add one!')}
            </Link>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

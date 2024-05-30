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
import {Flex} from '@instructure/ui-flex'
import { ToggleDetails } from '@instructure/ui-toggle-details'
import {useScope as useI18nScope} from '@canvas/i18n'
import SearchResult from './SearchResult'

const I18n = useI18nScope('SmartSearch')

export default function SearchResults({onDislike, onExplain, onLike, searchResults, searchTerm}) {
  const searchItemKey = ({content_id, content_type}) => `${content_type}_${content_id}`

  const topResults = searchResults.filter(result => result.relevance >= 50)
  const otherResults = searchResults.filter(result => result.relevance < 50)

  return (<>
    <Flex as="ul" className="searchResults" direction="column">
      {topResults.map(result => (
        <SearchResult
          key={searchItemKey(result)}
          result={result}
          onDislike={onDislike}
          onExplain={onExplain}
          onLike={onLike}
          searchTerm={searchTerm}
        />
      ))}
    </Flex>
    {otherResults.length > 0 && (
      <ToggleDetails summary={I18n.t('Show additional results that may be less relevant')}>
        <Flex as="ul" className="searchResults" direction="column">
          {searchResults.filter(result => result.relevance < 50).map(result => (
            <SearchResult
              key={searchItemKey(result)}
              result={result}
              onDislike={onDislike}
              onExplain={onExplain}
              onLike={onLike}
              searchTerm=""
            />
          ))}
        </Flex>
      </ToggleDetails>
    )}
  </>)
}

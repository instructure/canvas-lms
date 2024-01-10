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
import SearchResult from './SearchResult'

export default function SearchResults(props) {
  function searchItemKey(searchItem) {
    if (searchItem.wiki_page) {
      return 'wiki_page-' + searchItem.wiki_page.id
    } // TODO: add other search item types
    return 'unknown'
  }

  return (
    <Flex as="div" direction="column">
      {props.searchResults.map(s => (
        <Flex.Item key={searchItemKey(s)} as="div">
          <SearchResult searchResult={s} />
        </Flex.Item>
      ))}
    </Flex>
  )
}

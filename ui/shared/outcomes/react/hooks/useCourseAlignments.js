/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useState, useEffect, useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useQuery} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {SEARCH_OUTCOME_ALIGNMENTS} from '../../graphql/Management'
import useCanvasContext from './useCanvasContext'
import useSearch from './useSearch'

const I18n = useI18nScope('AlignmentSummary')

const useCourseAlignments = () => {
  const {contextType, contextId, rootOutcomeGroup} = useCanvasContext()
  const [searchFilter, setSearchFilter] = useState('ALL_OUTCOMES')
  const {search: searchString, onChangeHandler, onClearHandler} = useSearch()

  // Don't trigger search if search string < 3 chars
  const searchStore = useRef('')
  const debounceSearchString = searchStr => {
    const str = searchStr || ''
    if (![1, 2].includes(str.length)) searchStore.current = str
    return searchStore.current
  }

  const variables = {
    id: rootOutcomeGroup.id,
    outcomesContextType: contextType,
    outcomesContextId: contextId,
    searchFilter
  }
  const debouncedString = debounceSearchString(searchString)
  if (debouncedString) variables.searchQuery = debouncedString

  const {loading, error, data, fetchMore} = useQuery(SEARCH_OUTCOME_ALIGNMENTS, {
    variables,
    fetchPolicy: 'network-only'
  })

  useEffect(() => {
    if (error) {
      showFlashAlert({
        message: I18n.t('An error occurred while loading outcome alignments.'),
        type: 'error'
      })
    }
  }, [error])

  const loadMore = () => {
    if (!loading) {
      fetchMore({
        variables: {
          outcomesCursor: data?.group?.outcomes?.pageInfo?.endCursor
        },
        updateQuery: (prevData, {fetchMoreResult}) => ({
          ...prevData,
          group: {
            ...prevData.group,
            outcomes: {
              ...prevData.group.outcomes,
              edges: [...prevData.group.outcomes.edges, ...fetchMoreResult.group.outcomes.edges],
              pageInfo: fetchMoreResult.group.outcomes.pageInfo
            }
          }
        })
      })
    }
  }

  return {
    rootGroup: data?.group || null,
    loading,
    error,
    loadMore,
    searchString,
    onSearchChangeHandler: onChangeHandler,
    onSearchClearHandler: onClearHandler,
    searchFilter,
    onFilterChangeHandler: setSearchFilter
  }
}

export default useCourseAlignments

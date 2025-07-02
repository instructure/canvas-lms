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

import {useScope as createI18nScope} from '@canvas/i18n'
import {useCallback, useEffect, useRef, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import type {IndexProgress, Result} from '../types'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {IconAiSolid, IconAiColoredSolid} from '@instructure/ui-icons'
import AutocompleteSearch from './AutocompleteSearch'
import {useSearchParams} from 'react-router-dom'

const I18n = createI18nScope('SmartSearch')

const MAX_NUMBER_OF_RESULTS = 25
const MAX_RECENT_SEARCHES = 25 // Maximum number of recent searches to store

interface Props {
  courseId: string
  isLoading: boolean
  onSearch: (query: string) => void
  onSuccess: (results: Result[]) => void
  onError: (error: string) => void
  onIndexingProgress: (progress: IndexProgress | null) => void
}

const executeSmartSearch = async (searchQuery: string, courseId: string) => {
  const params = {
    q: searchQuery,
    per_page: MAX_NUMBER_OF_RESULTS,
    include: ['modules', 'status'],
  }
  const {json} = await doFetchApi<{results: Result[]}>({
    path: `/api/v1/courses/${courseId}/smartsearch`,
    params,
  })
  return json
}

/*
 * This component is incomplete.
 * Will eventually contain the branding and updated search button.
 * For now, it simply displays a search bar.
 */
export default function SmartSearchHeader(props: Props) {
  const searchInput = useRef<HTMLInputElement | null>(null)
  const [searchParam, setSearchParams] = useSearchParams()
  const [recentSearches, setRecentSearches] = useState<string[]>([])

  useEffect(() => {
    const localSearches = localStorage.getItem('recentSmartSearches') || '[]'
    const parsedSearches = JSON.parse(localSearches)
    if (Array.isArray(parsedSearches)) {
      setRecentSearches(parsedSearches)
    }
  }, [])

  const updateRecentSearches = useCallback((searchTerm: string, recentSearches: string[]) => {
    const searches = recentSearches.filter(search => search !== searchTerm)
    const updatedSearches = [searchTerm, ...searches].slice(0, MAX_RECENT_SEARCHES)
    setRecentSearches(updatedSearches)
    localStorage.setItem('recentSmartSearches', JSON.stringify(updatedSearches))
  }, [])

  const onSearch = useCallback(
    async (useUrl: boolean) => {
      let searchTerm = searchInput.current?.value.trim() || ''
      const queryParam = searchParam.get('q')
      if (useUrl) {
        // search based on the URL
        searchTerm = queryParam || searchTerm
      } else if (queryParam !== searchTerm) {
        // update the URL with the new search term
        setSearchParams(prevParams => {
          return {
            ...prevParams,
            q: searchTerm,
          }
        })
      }
      if (searchTerm === '') return

      props.onSearch(searchTerm)

      try {
        const json = await executeSmartSearch(searchTerm, props.courseId)
        props.onSuccess(json!.results)
      } catch (error) {
        props.onError(I18n.t('Failed to execute search: ') + error)
      } finally {
        updateRecentSearches(searchTerm, recentSearches)
      }
    },
    [props, recentSearches, searchParam, setSearchParams, updateRecentSearches],
  )

  const checkIndexStatus = useCallback(async () => {
    try {
      const {json} = await doFetchApi<IndexProgress>({
        path: `/api/v1/courses/${props.courseId}/smartsearch/index_status`,
      })
      if (json && json.status === 'indexing') {
        props.onIndexingProgress(json)
        setTimeout(checkIndexStatus, 2000)
      } else {
        props.onIndexingProgress(null)
        onSearch(true)
      }
    } catch (error) {
      props.onError(I18n.t('Failed to check index status: ') + error)
    }
  }, [onSearch, props])

  useEffect(() => {
    if (searchInput.current) {
      searchInput.current.focus()
    }
    checkIndexStatus()
    // only run this effect once component mounts
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <>
      <Heading variant="titlePageDesktop" data-testid="smart-search-heading">
        <Flex alignItems="center" gap="small">
          <IconAiColoredSolid size="small" />
          {I18n.t('Smart Search')}
        </Flex>
      </Heading>
      <Flex
        width="495px"
        gap="x-small"
        as="form"
        onSubmit={e => {
          e.preventDefault()
          onSearch(false)
        }}
      >
        <Flex.Item shouldGrow>
          <AutocompleteSearch
            defaultValue={searchParam.get('q') || ''}
            setInputRef={input => {
              searchInput.current = input
            }}
            isLoading={props.isLoading}
            options={recentSearches}
          />
        </Flex.Item>
        <Button
          color="ai-primary"
          renderIcon={<IconAiSolid />}
          type="submit"
          data-testid="search-button"
        >
          {I18n.t('Search')}
        </Button>
      </Flex>
    </>
  )
}

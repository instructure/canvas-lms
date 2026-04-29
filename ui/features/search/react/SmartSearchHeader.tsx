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
import type {IndexProgress, Result} from './types'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {IconAiSolid, IconAiColoredSolid, IconFilterLine, IconXLine} from '@instructure/ui-icons'
import AutocompleteSearch from './AutocompleteSearch'
import {useSearchParams} from 'react-router-dom'
import {Tray} from '@instructure/ui-tray'
import SmartSearchFilters, {ALL_SOURCES} from './SmartSearchFilters'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {Link} from '@instructure/ui-link'
import {InlineList, InlineListItem} from '@instructure/ui-list'

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
  setSearchInputRef: (input: HTMLInputElement | null) => void
}

const executeSmartSearch = async (
  searchQuery: string,
  courseId: string,
  filters: (string | number)[] = [],
) => {
  const params = {
    q: searchQuery,
    per_page: MAX_NUMBER_OF_RESULTS,
    filter: filters.includes('all') ? [] : filters,
    include: ['modules', 'status'],
  }
  const {json} = await doFetchApi<{results: Result[]}>({
    path: `/api/v1/courses/${courseId}/smartsearch`,
    params,
  })
  return json
}

const SMALL_WINDOW = 850

export default function SmartSearchHeader(props: Props) {
  const searchInput = useRef<HTMLInputElement | null>(null)
  const [windowWidth, setWindowWidth] = useState(window.innerWidth)
  const [searchParam, setSearchParams] = useSearchParams()
  const [recentSearches, setRecentSearches] = useState<string[]>([])
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState<(string | number)[]>(ALL_SOURCES)

  const readableFilters: Record<string, string> = {
    all: I18n.t('All'),
    assignments: I18n.t('Assignments'),
    announcements: I18n.t('Announcements'),
    discussion_topics: I18n.t('Discussions'),
    pages: I18n.t('Pages'),
  }

  useEffect(() => {
    const localSearches = localStorage.getItem('recentSmartSearches') || '[]'
    const parsedSearches = JSON.parse(localSearches)
    if (Array.isArray(parsedSearches)) {
      setRecentSearches(parsedSearches)
    }

    function handleResize() {
      setWindowWidth(window.innerWidth)
    }
    window.addEventListener('resize', handleResize)
    return () => {
      window.removeEventListener('resize', handleResize)
    }
  }, [])

  const updateRecentSearches = useCallback((searchTerm: string, recentSearches: string[]) => {
    const searches = recentSearches.filter(search => search !== searchTerm)
    const updatedSearches = [searchTerm, ...searches].slice(0, MAX_RECENT_SEARCHES)
    setRecentSearches(updatedSearches)
    localStorage.setItem('recentSmartSearches', JSON.stringify(updatedSearches))
  }, [])

  const onSearch = useCallback(
    async (useUrl: boolean, filters: (string | number)[]) => {
      let searchTerm = searchInput.current?.value.trim() || ''
      const queryParam = searchParam.get('q')
      if (useUrl) {
        // search based on the URL
        searchTerm = queryParam || searchTerm
      } else if (queryParam !== searchTerm) {
        // update the URL with the new search term
        setSearchParams(prevParams => {
          const newParams = new URLSearchParams(prevParams)
          newParams.set('q', searchTerm)
          return newParams
        })
      }
      if (searchTerm === '') return

      props.onSearch(searchTerm)

      try {
        const json = await executeSmartSearch(searchTerm, props.courseId, filters)
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
        onSearch(true, filters)
      }
    } catch (error) {
      props.onError(I18n.t('Failed to check index status: ') + error)
    }
  }, [onSearch, props, filters])

  useEffect(() => {
    if (searchInput.current) {
      searchInput.current.focus()
    }
    checkIndexStatus()
    // only run this effect once component mounts
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleFilterChange = (newFilters: (string | number)[]) => {
    setFilters(newFilters)
    if (props.isLoading) return // don't trigger search if already loading
    onSearch(false, newFilters)
  }

  const renderFilters = () => {
    return (
      <InlineList itemSpacing="xxx-small">
        <InlineListItem margin="dataPoints 0 0">
          <Text>{I18n.t('Filters')}</Text>
        </InlineListItem>

        {filters.map(filter => {
          return (
            <InlineListItem key={filter} margin="dataPoints 0 0">
              <Pill
                data-testid={`filter-pill-${filter}`}
                onClick={() => {
                  handleFilterChange(filters.filter(f => f !== filter))
                }}
                renderIcon={<IconXLine />}
              >
                <PresentationContent>{readableFilters[filter]}</PresentationContent>
                <ScreenReaderContent>
                  {I18n.t('Remove filter: %{filter}', {filter: readableFilters[filter]})}
                </ScreenReaderContent>
              </Pill>
            </InlineListItem>
          )
        })}
        <InlineListItem key="clear-all" margin="dataPoints 0 0">
          <Link as="button" onClick={() => handleFilterChange([])}>
            {I18n.t('Clear all')}
          </Link>
        </InlineListItem>
      </InlineList>
    )
  }

  const renderSearchBar = () => {
    // biggest
    if (windowWidth > SMALL_WINDOW) {
      // adjust width based on window width
      const auto_width = 100 + windowWidth / 4
      return (
        <Flex justifyItems="space-between" gap="buttons">
          {/* need to override form css styling in Flex (defaults to margin: 0 0 22px) */}
          <Flex
            margin="0"
            gap="buttons"
            as="form"
            onSubmit={e => {
              e.preventDefault()
              onSearch(false, filters)
            }}
          >
            <Flex.Item shouldGrow>
              <AutocompleteSearch
                width={`${auto_width}px`}
                defaultValue={searchParam.get('q') || ''}
                setInputRef={input => {
                  searchInput.current = input
                  props.setSearchInputRef(input)
                }}
                isLoading={props.isLoading}
                options={recentSearches}
              />
            </Flex.Item>
            <Button
              disabled={props.isLoading}
              color="ai-primary"
              renderIcon={<IconAiSolid />}
              type="submit"
              data-testid="search-button"
            >
              {I18n.t('Search')}
            </Button>
          </Flex>
          <Button
            data-testid="filter-button"
            renderIcon={<IconFilterLine />}
            onClick={() => setShowFilters(true)}
          >
            {I18n.t('Filters')}
          </Button>
        </Flex>
      )
    } else {
      return (
        <Flex gap="buttons" direction="column">
          {/* need to override form css styling in Flex (defaults to margin: 0 0 22px) */}
          <Flex
            margin="0"
            gap="buttons"
            as="form"
            onSubmit={e => {
              e.preventDefault()
              onSearch(false, filters)
            }}
          >
            <Flex.Item shouldGrow>
              <Flex gap="buttons">
                <Flex.Item shouldGrow shouldShrink>
                  <AutocompleteSearch
                    defaultValue={searchParam.get('q') || ''}
                    setInputRef={input => {
                      searchInput.current = input
                      props.setSearchInputRef(input)
                    }}
                    isLoading={props.isLoading}
                    options={recentSearches}
                  />
                </Flex.Item>
                <Button
                  disabled={props.isLoading}
                  color="ai-primary"
                  renderIcon={<IconAiSolid />}
                  type="submit"
                  data-testid="search-button"
                >
                  {I18n.t('Search')}
                </Button>
              </Flex>
            </Flex.Item>
          </Flex>
          <Button
            data-testid="filter-button"
            renderIcon={<IconFilterLine />}
            onClick={() => setShowFilters(true)}
          >
            {I18n.t('Filters')}
          </Button>
        </Flex>
      )
    }
  }

  return (
    <>
      <Flex direction="column" gap="sections">
        <Heading variant="titlePageDesktop" level="h1" data-testid="smart-search-heading">
          <Flex alignItems="center" gap="small">
            <IconAiColoredSolid size="small" />
            <ScreenReaderContent>{I18n.t('Ignite AI')}</ScreenReaderContent>
            {I18n.t('IgniteAI Search')}
          </Flex>
        </Heading>
        {renderSearchBar()}
        {filters.length > 0 && !filters.includes('all') && renderFilters()}
      </Flex>
      <Tray
        open={showFilters}
        label={I18n.t('IgniteAI Search filters')}
        placement="end"
        onDismiss={() => setShowFilters(false)}
      >
        <SmartSearchFilters
          handleCloseTray={() => setShowFilters(false)}
          updateFilters={sources => {
            handleFilterChange(sources)
            setShowFilters(false)
          }}
          filters={filters.length === 0 || filters.includes('all') ? filters : [...filters, 'all']}
        />
      </Tray>
    </>
  )
}

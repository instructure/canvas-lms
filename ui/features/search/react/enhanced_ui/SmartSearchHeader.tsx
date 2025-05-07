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
import {useCallback, useEffect, useRef} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconSearchLine} from '@instructure/ui-icons'
import type {IndexProgress, Result} from '../types'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('SmartSearch')

const MAX_NUMBER_OF_RESULTS = 25

interface Props {
  courseId: string
  isLoading: boolean
  onSearch: (query: string) => void
  onSuccess: (results: Result[]) => void
  onError: (error: string) => void
  onIndexingProgress: (progress: IndexProgress | null) => void
}

/*
 * This component is incomplete.
 * Will eventually contain the branding and updated search button.
 * For now, it simply displays a search bar.
 */
export default function SmartSearchHeader(props: Props) {
  const searchInput = useRef<HTMLInputElement | null>(null)

  const onSearch = async () => {
    if (!searchInput.current) return

    const searchTerm = searchInput.current.value.trim()
    if (searchTerm === '') return

    props.onSearch(searchTerm)

    const url = new URL(window.location.href)
    if (url.searchParams.get('q') !== searchTerm) {
      url.searchParams.set('q', searchTerm)
      window.history.pushState({}, '', url)
    }

    try {
      const params = {
        q: searchTerm,
        per_page: MAX_NUMBER_OF_RESULTS,
        include: ['modules', 'status'],
      }
      const {json} = await doFetchApi<{results: Result[]}>({
        path: `/api/v1/courses/${props.courseId}/smartsearch`,
        params,
      })
      props.onSuccess(json!.results)
    } catch (error) {
      props.onError(I18n.t('Failed to execute search: ') + error)
    }
  }

  const doUrlSearch = useCallback((perform = true) => {
    const url = new URL(window.location.href)
    const searchTerm = url.searchParams.get('q')
    if (searchTerm && searchTerm.length && searchInput.current) {
      searchInput.current.value = searchTerm
      if (perform) {
        onSearch()
      }
    }
  }, [])

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
        doUrlSearch()
      }
    } catch (error) {
      props.onError(I18n.t('Failed to check index status: ') + error)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    doUrlSearch(false) // init the box but don't actually do the search until we've checked index status
    if (searchInput.current) {
      searchInput.current.focus()
    }
    checkIndexStatus()
    window.addEventListener('popstate', () => doUrlSearch())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <>
      <Heading level="h1" data-testid="smart-search-heading">
        {I18n.t('Smart Search')}
      </Heading>
      <Flex
        gap="x-small"
        as="form"
        onSubmit={e => {
          e.preventDefault()
          onSearch()
        }}
      >
        <TextInput
          data-testid="search-input"
          inputRef={el => (searchInput.current = el)}
          placeholder={I18n.t('Food that a panda eats')}
          renderAfterInput={
            <IconButton
              interaction={props.isLoading ? 'disabled' : 'enabled'}
              renderIcon={<IconSearchLine />}
              withBackground={false}
              withBorder={false}
              screenReaderLabel={'Search'}
              type="submit"
            />
          }
          renderLabel=""
        />
        <Button color="primary" type="submit" data-testid="search-button">
          {I18n.t('Search')}
        </Button>
      </Flex>
    </>
  )
}

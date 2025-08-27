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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {Select} from '@instructure/ui-select'
import {QueryFunctionContext, QueryKey, useInfiniteQuery} from '@tanstack/react-query'
import {EnrollmentTerms, Term} from 'api'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {useDebouncedCallback} from 'use-debounce'
import {useEffect, useRef, useState} from 'react'

const I18n = createI18nScope('sis_import')

interface Props {
  accountId: string
  onSelect: (termId: string) => void
  isVisible: boolean
}

const fetchTerms = async ({
  queryKey,
  pageParam = '1',
}: QueryFunctionContext<QueryKey, string>): Promise<{
  json: EnrollmentTerms
  nextPage: string | null
}> => {
  const [, accountId, termName] = queryKey as string[]
  const params = {
    per_page: 100,
    page: pageParam,
    term_name: termName,
  }
  const {json, link} = await doFetchApi<EnrollmentTerms>({
    path: `/api/v1/accounts/${accountId}/terms`,
    params,
  })
  const nextPage = link?.next ? link.next.page : null
  return {json: json || {enrollment_terms: []}, nextPage: nextPage}
}

export default function FullBatchDropdown(props: Props) {
  const observerRef = useRef<IntersectionObserver | null>(null)
  const [firstLoad, setFirstLoad] = useState(true)
  const [termName, setTermName] = useState('')
  const [debouncedTermName, setDebouncedTermName] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [selectedOption, setSelectedOption] = useState<Term | null>(null)
  const [highlightedOption, setHighlightedOption] = useState<Term | null>(null)

  const fullBatchWarning = I18n.t(
    'If selected, this will delete everything for this term, which includes all courses and enrollments that are not in the selected import file above. See the documentation for details.',
  )

  const debouncedSearch = useDebouncedCallback((value: string) => {
    setDebouncedTermName(value)
  }, 500) // 1/2 second debounce

  const {data, fetchNextPage, isFetching, hasNextPage, error} = useInfiniteQuery({
    queryKey: ['terms_list', props.accountId, debouncedTermName],
    queryFn: fetchTerms,
    getNextPageParam: lastPage => lastPage.nextPage,
    initialPageParam: '1',
  })

  useEffect(() => {
    if (!data?.pages || data?.pages?.length === 0) {
      return
    }

    if (firstLoad) {
      const firstTerm = data.pages[0].json.enrollment_terms[0]
      if (firstTerm) {
        setTermName(firstTerm.name)
        setSelectedOption(firstTerm)
        props.onSelect(firstTerm.id)
        setHighlightedOption(null)
      }
      setFirstLoad(false)
    } else if (data.pages.length === 1) {
      // when we do a fuzzy search, update top term to be highlighted
      const firstTerm = data.pages[0].json.enrollment_terms[0]
      setHighlightedOption(firstTerm)
    }
  }, [data, firstLoad])

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null || !hasNextPage) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        fetchNextPage()
        clearPageLoadTrigger()
      }
    })
    observerRef.current.observe(ref)
  }

  const matchValue = (terms: Term[]) => {
    const matchesSelected = terms.some(
      term => term.name === termName && term.id === selectedOption?.id,
    )
    if (matchesSelected) {
      // stick with the selected option; do nothing
      return
    } else if (terms.length >= 1) {
      const onlyOption = terms[0]
      // automatically select the matching option
      setTermName(onlyOption.name)
      setSelectedOption(onlyOption)
      props.onSelect(onlyOption.id)
    }
    // stick with our last term name if input is empty
    else if (selectedOption) {
      const name = selectedOption.name
      setTermName(name)
    }
  }

  const handleHighlightOption = (event: React.SyntheticEvent, id: string) => {
    event.persist()
    const option = terms.find(term => term.id === id)
    if (!option) return // prevent highlighting of empty option
    setHighlightedOption(option)
  }

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    debouncedSearch.cancel()
    if (!isShowingOptions) {
      setIsShowingOptions(true)
    }
    setTermName(value)
    debouncedSearch(value)
  }

  const handleShowOptions = (event: React.SyntheticEvent) => {
    setIsShowingOptions(true)
    if (terms.length === 0) return

    const keyboardEvent = event as React.KeyboardEvent
    switch (keyboardEvent.key) {
      case 'ArrowDown':
        return handleHighlightOption(event, terms[0].id)
      case 'ArrowUp':
        return handleHighlightOption(event, terms[terms.length - 1].id)
    }
  }

  const handleHideOptions = (terms: Term[]) => {
    debouncedSearch.cancel()
    setIsShowingOptions(false)
    setHighlightedOption(null)
    matchValue(terms)
  }

  const handleBlur = () => {
    setIsShowingOptions(false)
    setHighlightedOption(null)
    matchValue(terms)
  }

  const handleSelectOption = (_event: React.SyntheticEvent, terms: Term[], id: string) => {
    const option = terms.find(term => term.id === id)
    if (!option) return // prevent selecting of empty option
    setSelectedOption(option)
    setIsShowingOptions(false)
    setTermName(option.name)
    debouncedSearch(option.name)
    props.onSelect(id)
  }

  const terms =
    data?.pages.reduce((acc: Term[], page) => {
      return acc.concat(page.json.enrollment_terms)
    }, []) || []

  const renderObserver = () => {
    if (isFetching && data?.pages && data.pages.length >= 1) {
      return (
        <Select.Option key="loading-next-page" id="loading" disabled={true} value="loading">
          <Spinner size="small" renderTitle={I18n.t('Loading more terms')} data-testid="spinner" />
        </Select.Option>
      )
    } else if (hasNextPage) {
      return (
        <Select.Option key="observer" id="observer" disabled={true} value="observer">
          <span ref={ref => setPageLoadTrigger(ref)} />
        </Select.Option>
      )
    }
  }

  const isLoadingTerms = isFetching || debouncedSearch.isPending()
  if (!props.isVisible) {
    return null
  } else if (error) {
    return <Alert variant="error">{I18n.t('Error loading terms')}</Alert>
  } else {
    return (
      <View margin="0 0 0 medium">
        <Alert variant="warning" margin="small" data-testid="full-batch-warning">
          {fullBatchWarning}
        </Alert>
        <Select
          data-testid="full-batch-dropdown"
          width="50%"
          renderLabel={I18n.t('Term')}
          assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
          placeholder={I18n.t('Start typing to search...')}
          isShowingOptions={isShowingOptions && (terms.length > 0 || isLoadingTerms)}
          inputValue={termName}
          onBlur={handleBlur}
          onRequestHighlightOption={(event, {id}) => handleHighlightOption(event, id ?? '')}
          onInputChange={handleInputChange}
          onRequestShowOptions={handleShowOptions}
          onRequestHideOptions={() => handleHideOptions(terms)}
          onRequestSelectOption={(event, data) => handleSelectOption(event, terms, data.id ?? '')}
        >
          {isLoadingTerms && !data ? (
            <Select.Option id="loading" disabled={true} value="loading">
              <Spinner size="small" renderTitle={I18n.t('Loading terms')} data-testid="spinner" />
            </Select.Option>
          ) : (
            terms.map(term => (
              <Select.Option
                key={term.id}
                id={term.id}
                data-testid={`option-${term.id}`}
                value={term.id}
                isHighlighted={term.id === highlightedOption?.id}
                isSelected={term.id === selectedOption?.id}
              >
                {term.name}
              </Select.Option>
            ))
          )}
          {hasNextPage ? renderObserver() : null}
        </Select>
      </View>
    )
  }
}

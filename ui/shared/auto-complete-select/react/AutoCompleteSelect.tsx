/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useRef, useState, type ComponentProps} from 'react'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {QueryParameterRecord} from '@instructure/query-string-encoding'

const I18n = createI18nScope('course_logging_content')

interface SelectState<T> {
  value: string
  isShowingOption: boolean
  highlightedOptionId: string | null
  selectedOptionId: string | null
  isLoading: boolean
  fetchedOptions: Array<T>
  error: Error | null
}

export interface AutoCompleteSelectProps<T> extends ComponentProps<typeof Select> {
  url: string
  renderOptionLabel: (option: T) => string
  fetchParams?: QueryParameterRecord
  overrideSelectProps?: Partial<ComponentProps<typeof Select>>
  overrideSelectOptionProps?: Partial<ComponentProps<typeof Select.Option>>
}

const AutoCompleteSelect = <T extends {id: string}>({
  url,
  renderOptionLabel,
  fetchParams,
  overrideSelectProps,
  overrideSelectOptionProps,
  ...selectProps
}: AutoCompleteSelectProps<T>) => {
  const [selectState, setSelectState] = useState<SelectState<T>>({
    value: '',
    isShowingOption: false,
    highlightedOptionId: null,
    selectedOptionId: null,
    isLoading: false,
    fetchedOptions: [],
    error: null,
  })
  const abortControllerRef = useRef<AbortController | null>(null)

  const shouldSendRequest = (searchTerm: string) => searchTerm.length >= 3

  const selectOptions = selectState.fetchedOptions.length ? (
    selectState.fetchedOptions.map(option => (
      <Select.Option
        id={option.id}
        key={option.id}
        isHighlighted={selectState.highlightedOptionId === option.id}
        isSelected={selectState.selectedOptionId === option.id}
        {...overrideSelectOptionProps}
      >
        {renderOptionLabel(option)}
      </Select.Option>
    ))
  ) : (
    <Select.Option id="empty-option" key="empty-option" isDisabled={true}>
      {selectState.isLoading ? (
        <Spinner renderTitle="Loading" size="x-small" />
      ) : shouldSendRequest(selectState.value) ? (
        I18n.t('No results')
      ) : (
        I18n.t('Type to search')
      )}
    </Select.Option>
  )

  return (
    <Select
      {...selectProps}
      isShowingOptions={selectState.isShowingOption}
      inputValue={selectState.value}
      onInputChange={(event, value) => {
        const searchTerm = event.target.value

        setSelectState(prevState => ({
          ...prevState,
          value: searchTerm,
        }))
        selectProps?.onInputChange?.(event, value)

        if (shouldSendRequest(searchTerm)) {
          if (abortControllerRef.current) {
            abortControllerRef.current.abort()
          }

          abortControllerRef.current = new AbortController()

          setSelectState(prevState => ({
            ...prevState,
            isLoading: true,
            isShowingOption: true,
            highlightedOptionId: null,
            selectedOptionId: null,
          }))

          doFetchApi<Array<T>>({
            path: url,
            method: 'GET',
            params: {search_term: searchTerm, ...fetchParams},
            signal: abortControllerRef.current.signal,
          })
            .then(({json}) => {
              setSelectState(prevState => ({
                ...prevState,
                fetchedOptions: json ?? [],
                isLoading: false,
                error: null,
              }))
            })
            .catch(error => {
              setSelectState(prevState => ({
                ...prevState,
                error,
                isLoading: false,
              }))
            })
        } else {
          setSelectState(prevState => ({...prevState, fetchedOptions: [], error: null}))
        }
      }}
      onRequestShowOptions={args => {
        setSelectState(prevState => ({
          ...prevState,
          isShowingOption: true,
        }))
        selectProps?.onRequestShowOptions?.(args)
      }}
      onRequestHideOptions={args => {
        setSelectState(prevState => ({
          ...prevState,
          isShowingOption: false,
          highlightedOptionId: null,
        }))
        selectProps?.onRequestHideOptions?.(args)
      }}
      onRequestHighlightOption={(event, {id}) => {
        setSelectState(prevState => ({
          ...prevState,
          highlightedOptionId: id ?? null,
        }))
        selectProps?.onRequestHighlightOption?.(event, {id})
      }}
      onRequestSelectOption={(event, {id}) => {
        setSelectState(prevState => {
          const selectedOption = prevState.fetchedOptions.find(option => option.id === id)

          return {
            ...prevState,
            selectedOptionId: id ?? null,
            isShowingOption: false,
            fetchedOptions: [selectedOption!],
            value: renderOptionLabel(selectedOption!),
          }
        })
        selectProps?.onRequestSelectOption?.(event, {id})
      }}
      {...overrideSelectProps}
    >
      {selectOptions}
    </Select>
  )
}

export default AutoCompleteSelect

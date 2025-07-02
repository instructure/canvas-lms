/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, {useState, useEffect, useCallback, ReactNode} from 'react'

import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from './hooks/useDebouncedSearchTerm'

interface SearchItem {
  id: string
  name: string
  [key: string]: any
}

interface SearchItemSelectorProps {
  onItemSelected?: (item: SearchItem | null) => void
  itemSearchFunction?: (params: {
    success: (items: SearchItem[]) => void
    error: (error: Error) => void
    loading: (isLoading: boolean) => void
    params: Record<string, any>
  }) => void
  renderLabel?: ReactNode
  contextId?: string
  renderOption?: (item: SearchItem) => ReactNode
  additionalParams?: Record<string, any>
  minimumSearchLength?: number
  isSearchableTerm?: (term: string) => boolean
  placeholder?: string | null
  manualSelection?: string | null
  mountNodeRef?: React.RefObject<Element> | null
  onInputChanged?: (event: React.ChangeEvent<HTMLInputElement>) => void
  inputRef?: ((element: HTMLInputElement | null) => void) | null
  messages?: Array<{
    text: string
    type: string
  }>
  isRequired?: boolean
  id?: string | null
}

const I18n = createI18nScope('managed_course_selector')
const MINIMUM_SEARCH_LENGTH = 2

export default function SearchItemSelector({
  onItemSelected = () => {},
  renderLabel = '',
  itemSearchFunction = () => {},
  contextId = '',
  renderOption = undefined,
  additionalParams = {},
  mountNodeRef = null,
  minimumSearchLength = MINIMUM_SEARCH_LENGTH,
  isSearchableTerm = (term: string) => (term?.length || 0) >= MINIMUM_SEARCH_LENGTH,
  placeholder = null,
  manualSelection = null,
  onInputChanged = () => {},
  inputRef = null,
  messages = [],
  isRequired = false,
  id = null,
}: SearchItemSelectorProps) {
  const [items, setItems] = useState<SearchItem[] | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [inputValue, setInputValue] = useState('')
  const [selectedItem, setSelectedItem] = useState<SearchItem | null>(null)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm,
  })

  useEffect(() => {
    handleInputChanged({target: {value: ''}} as React.ChangeEvent<HTMLInputElement>)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextId])

  // allow the parent to manually select an item known to exist
  useEffect(() => {
    if (typeof manualSelection === 'string') {
      setInputValue(manualSelection)
      setSelectedItem({id: '', name: manualSelection})
    }
  }, [manualSelection])

  // avoid actually searching for the manually selected term until we need to
  const onFocus = useCallback(() => {
    if (searchTerm !== inputValue) setSearchTerm(inputValue)
  }, [inputValue, searchTerm, setSearchTerm])

  const searchParams: Record<string, any> =
    searchTerm.length === 0 ? {} : {term: searchTerm, search_term: searchTerm}
  if (contextId) searchParams.contextId = contextId
  itemSearchFunction({
    success: setItems,
    error: setError,
    loading: setIsLoading,
    params: {...searchParams, ...additionalParams},
  })

  const handleItemSelected = (_ev: React.SyntheticEvent, id: string) => {
    if (items === null) return
    const item = items.find(i => i.id === id)
    if (!item) return

    setInputValue(item.name)
    setSelectedItem(item)
    onItemSelected(item)
  }

  const handleInputChanged = (ev: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(ev.target.value)
    setSearchTerm(ev.target.value)
    if (selectedItem !== null && !manualSelection) onItemSelected(null)
    setSelectedItem(null)
    onInputChanged(ev)
  }

  // If there's an error, throw it to an ErrorBoundary
  if (error !== null) throw error

  const searchableInput = isSearchableTerm(inputValue)
  const noOptionsLabel = searchableInput
    ? I18n.t('No Results')
    : I18n.t('Enter at least %{count} characters', {count: minimumSearchLength})
  const itemOptions =
    items === null
      ? undefined
      : (items.map(item => (
          <CanvasAsyncSelect.Option key={item.id} id={item.id}>
            {renderOption ? renderOption(item) : item.name}
          </CanvasAsyncSelect.Option>
        )) as React.ReactElement[])

  const selectProps = {
    isRequired,
    options: itemOptions,
    isLoading: isLoading || searchTermIsPending,
    inputValue,
    selectedOptionId: selectedItem ? selectedItem.id : undefined,
    assistiveText: I18n.t('Enter at least %{count} characters', {count: minimumSearchLength}),
    renderLabel,
    placeholder: placeholder || I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange: handleInputChanged,
    onOptionSelected: handleItemSelected,
    mountNode: mountNodeRef?.current,
    inputRef: inputRef || undefined,
    messages,
    onFocus,
    id: id || undefined,
  }
  return <CanvasAsyncSelect {...selectProps}>{itemOptions}</CanvasAsyncSelect>
}

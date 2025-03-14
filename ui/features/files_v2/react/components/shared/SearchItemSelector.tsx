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
import React, {
  useState,
  useEffect,
  useCallback,
  ReactNode,
  ChangeEvent,
  SyntheticEvent,
  useMemo,
} from 'react'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'

const I18n = createI18nScope('files_v2')
const MINIMUM_SEARCH_LENGTH = 2

type SearchItemSelectorProps<T> = {
  onItemSelected: (item: T | null) => void
  itemSearchFunction: (opts: object) => void
  renderLabel: ReactNode
  contextId?: string
  renderOption?: ((item: T) => ReactNode) | null
  additionalParams: object
  minimumSearchLength: number
  isSearchableTerm: (term: string) => boolean
  placeholder?: string | null
  manualSelection?: string | null
  mountNodeRef?: {
    current: Element
  } | null
  onInputChanged?: (event: React.ChangeEvent<HTMLInputElement>, value?: string) => void
  inputRef?: (inputElement: HTMLInputElement | null) => void
  messages?: {
    text: string
    type: string
  }[]
  fetchErrorMessage?: string
  isRequired?: boolean
  id?: string | null
}

type SearchItem = {
  id: string
  name: string
}

// Based on ui/shared/search-item-selector/react/SearchItemSelector.jsx adapted to TypeScript,
// and to be used in DirectShareCoursePanel
export default function SearchItemSelector<T extends SearchItem>({
  onItemSelected = () => {},
  renderLabel = '',
  itemSearchFunction = () => {},
  contextId = '',
  renderOption = null,
  additionalParams = {},
  mountNodeRef = null,
  minimumSearchLength = MINIMUM_SEARCH_LENGTH,
  isSearchableTerm = (term: string) => (term?.length || 0) >= MINIMUM_SEARCH_LENGTH,
  placeholder = null,
  manualSelection = null,
  onInputChanged = () => {},
  inputRef,
  messages = [],
  fetchErrorMessage,
  isRequired = false,
  id = null,
}: SearchItemSelectorProps<T>) {
  const [items, setItems] = useState<T[] | null>(null)
  const [error, setError] = useState(null)
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [inputValue, setInputValue] = useState<string>('')
  const [selectedItem, setSelectedItem] = useState<T | null>(null)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm,
  })

  useEffect(() => {
    handleInputChanged({target: {value: ''}} as ChangeEvent<HTMLInputElement>)
    // eslint-disable-next-line react-compiler/react-compiler
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextId])

  // allow the parent to manually select an item known to exist
  useEffect(() => {
    if (typeof manualSelection === 'string') {
      setInputValue(manualSelection)
      setSelectedItem({id: manualSelection, name: manualSelection} as T)
    }
  }, [manualSelection])

  // avoid actually searching for the manually selected term until we need to
  const onFocus = useCallback(() => {
    if (searchTerm !== inputValue) setSearchTerm(inputValue)
  }, [inputValue, searchTerm, setSearchTerm])

  const searchParams: Record<string, any> =
    searchTerm.length === 0 ? {} : {term: searchTerm, search_term: searchTerm}
  if (contextId) searchParams.contextId = contextId

  const setItemsFromRequest = useCallback((items: T[] | null) => {
    setItems(items)
    setError(null)
  }, [])

  itemSearchFunction({
    success: setItemsFromRequest,
    error: setError,
    loading: setIsLoading,
    params: {...searchParams, ...additionalParams},
  })

  const handleItemSelected = useCallback(
    (_ev: SyntheticEvent, id: string) => {
      if (items === null) return
      const item = items.find(i => i.id === id)
      if (!item) return

      setInputValue(item.name)
      setSelectedItem(item)
      onItemSelected(item)
    },
    [items, onItemSelected],
  )

  const handleInputChanged = useCallback(
    (ev: ChangeEvent<HTMLInputElement>) => {
      setInputValue(ev.target.value)
      setSearchTerm(ev.target.value)
      if (selectedItem !== null && !manualSelection) onItemSelected(null)
      setSelectedItem(null)
      onInputChanged(ev)
    },
    [manualSelection, onInputChanged, onItemSelected, selectedItem, setSearchTerm],
  )

  // If there's an error, throw it to an ErrorBoundary
  if (error !== null && !fetchErrorMessage) throw error

  const searchableInput = useMemo(
    () => isSearchableTerm(inputValue),
    [inputValue, isSearchableTerm],
  )

  const noOptionsLabel = useMemo(
    () =>
      searchableInput
        ? I18n.t('No Results')
        : I18n.t('Enter at least %{count} characters', {count: minimumSearchLength}),
    [minimumSearchLength, searchableInput],
  )

  const itemOptions = useMemo(() => {
    const options = items || []
    return options.map(item => (
      <CanvasAsyncSelect.Option key={item.id} id={item.id}>
        {renderOption ? renderOption(item) : item.name}
      </CanvasAsyncSelect.Option>
    ))
  }, [items, renderOption])

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
    inputRef,
    messages:
      error && fetchErrorMessage
        ? [...messages, {text: fetchErrorMessage, type: 'newError'}]
        : messages,
    onFocus,
    id,
  }
  return <CanvasAsyncSelect {...selectProps}>{itemOptions}</CanvasAsyncSelect>
}

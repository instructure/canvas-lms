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

import I18n from 'i18n!managed_course_selector'
import React, {useState, useEffect} from 'react'
import {func, string, object} from 'prop-types'

import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from '../hooks/useDebouncedSearchTerm'

const MINIMUM_SEARCH_LENGTH = 2

SearchItemSelector.propTypes = {
  onItemSelected: func, // expects each item to have the 'name' property
  itemSearchFunction: func,
  renderLabel: string,
  contextId: string,
  renderOption: func,
  additionalParams: object
}

SearchItemSelector.defaultProps = {
  onItemSelected: () => {},
  itemSearchFunction: () => {},
  renderLabel: '',
  additionalParams: {}
}

function isSearchableTerm(value) {
  return value.length === 0 || value.length >= MINIMUM_SEARCH_LENGTH
}

export default function SearchItemSelector({
  onItemSelected,
  renderLabel,
  itemSearchFunction,
  contextId = '',
  renderOption,
  additionalParams
}) {
  const [items, setItems] = useState(null)
  const [error, setError] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [inputValue, setInputValue] = useState('')
  const [selectedItem, setSelectedItem] = useState(null)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm
  })

  useEffect(() => {
    handleInputChanged({target: {value: ''}})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextId])

  const searchParams = searchTerm.length === 0 ? {} : {term: searchTerm, search_term: searchTerm}
  if (contextId) searchParams.contextId = contextId
  itemSearchFunction({
    success: setItems,
    error: setError,
    loading: setIsLoading,
    params: {...searchParams, ...additionalParams}
  })

  const handleItemSelected = (ev, id) => {
    if (items === null) return
    const item = items.find(i => i.id === id)
    if (!item) return

    setInputValue(item.name)
    setSelectedItem(item)
    onItemSelected(item)
  }

  const handleInputChanged = ev => {
    setInputValue(ev.target.value)
    setSearchTerm(ev.target.value)
    if (selectedItem !== null) onItemSelected(null)
    setSelectedItem(null)
  }

  // If there's an error, throw it to an ErrorBoundary
  if (error !== null) throw error

  const searchableInput = isSearchableTerm(inputValue)
  const noOptionsLabel = searchableInput
    ? I18n.t('No Results')
    : I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH})
  const itemOptions =
    items === null
      ? null
      : items.map(item => (
          <CanvasAsyncSelect.Option key={item.id} id={item.id}>
            {renderOption ? renderOption(item) : item.name}
          </CanvasAsyncSelect.Option>
        ))

  const selectProps = {
    options: itemOptions,
    isLoading: isLoading || searchTermIsPending,
    inputValue,
    selectedOptionId: selectedItem ? selectedItem.id : null,
    assistiveText: I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH}),
    renderLabel,
    placeholder: I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange: handleInputChanged,
    onOptionSelected: handleItemSelected
  }
  return <CanvasAsyncSelect {...selectProps}>{itemOptions}</CanvasAsyncSelect>
}

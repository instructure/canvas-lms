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

import React, {useState, useCallback, useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import {
  useModuleItemContent,
  ModuleItemContentType,
  ContentItem,
} from '../../hooks/queries/useModuleItemContent'

const I18n = createI18nScope('context_modules_v2')

interface ModuleItemAsyncSelectProps {
  itemType: ModuleItemContentType
  courseId: string
  selectedItemId?: string
  onSelectionChange: (itemId: string | null, item?: ContentItem | null) => void
  renderLabel: string
  messages?: Array<{text: string; type: string}>
  isRequired?: boolean
}

const MINIMUM_SEARCH_LENGTH = 2

export default function ModuleItemAsyncSelect({
  itemType,
  courseId,
  selectedItemId,
  onSelectionChange,
  renderLabel,
  messages = [],
  isRequired = false,
}: ModuleItemAsyncSelectProps) {
  const [selectedItem, setSelectedItem] = useState<ContentItem | null>(null)
  const [inputValue, setInputValue] = useState('')

  const isSearchableTerm = useCallback(
    (term: string) => term.length === 0 || term.length >= MINIMUM_SEARCH_LENGTH,
    [],
  )

  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    timeout: 750,
    isSearchableTerm,
  })

  const {data, isLoading, isError} = useModuleItemContent(
    itemType,
    courseId,
    searchTerm,
    searchTerm.length >= MINIMUM_SEARCH_LENGTH,
  )

  const allItems = useMemo(() => {
    return data?.pages?.flatMap(page => page.items) || []
  }, [data?.pages])

  useEffect(() => {
    if (!selectedItemId) {
      setSelectedItem(null)
      if (selectedItem) {
        setInputValue('')
      }
    } else if (allItems.length > 0) {
      const item = allItems.find(item => item.id === selectedItemId)
      if (item && (!selectedItem || selectedItem.id !== selectedItemId)) {
        setSelectedItem(item)
        setInputValue(item.name)
      }
    }
  }, [selectedItemId, allItems, selectedItem])

  const handleInputChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = event.target.value
      setInputValue(newValue)
      setSearchTerm(newValue)

      if (!selectedItem || newValue !== selectedItem.name) {
        setSelectedItem(null)
        onSelectionChange(null, null)
      }
    },
    [selectedItem, setSearchTerm, onSelectionChange],
  )

  const handleItemSelected = useCallback(
    (_event: React.SyntheticEvent, itemId: string) => {
      const foundItem = allItems.find(item => item.id === itemId)
      if (!foundItem) return

      setSelectedItem(foundItem)
      setInputValue(foundItem.name)
      onSelectionChange(itemId, foundItem)
    },
    [allItems, onSelectionChange],
  )

  if (isError) {
    return (
      <CanvasAsyncSelect
        renderLabel={renderLabel}
        isLoading={false}
        noOptionsLabel={I18n.t('Error loading content')}
        onInputChange={() => {}}
        onOptionSelected={() => {}}
        messages={[{text: I18n.t('Error loading content'), type: 'error'}]}
      />
    )
  }

  const actuallyLoading = isLoading || searchTermIsPending

  const noOptionsLabel =
    searchTerm.length > 0 && searchTerm.length < MINIMUM_SEARCH_LENGTH
      ? I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH})
      : I18n.t('No items found')

  const filteredItems =
    itemType === 'assignment' ? allItems.filter((item: any) => !item.isQuiz) : allItems

  const itemOptions = filteredItems.map(item => (
    <CanvasAsyncSelect.Option key={item.id} id={item.id}>
      {item.name}
    </CanvasAsyncSelect.Option>
  ))

  return (
    <CanvasAsyncSelect
      data-testid="add-item-content-select"
      renderLabel={renderLabel}
      assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
      inputValue={inputValue}
      selectedOptionId={selectedItem?.id}
      isLoading={actuallyLoading}
      noOptionsLabel={noOptionsLabel}
      placeholder={I18n.t('Begin typing to search')}
      onInputChange={handleInputChange}
      onOptionSelected={handleItemSelected}
      messages={messages}
      isRequired={isRequired}
    >
      {itemOptions}
    </CanvasAsyncSelect>
  )
}

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

import React, {useState, useCallback, useEffect, useRef, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Select} from '@instructure/ui-select'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import {Tag} from '@instructure/ui-tag'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {
  useModuleItemContent,
  ModuleItemContentType,
  ContentItem,
} from '../../hooks/queries/useModuleItemContent'

const I18n = createI18nScope('context_modules_v2')

import type {FormMessage} from '@instructure/ui-form-field'

interface ModuleItemMultiSelectProps {
  itemType: ModuleItemContentType
  courseId: string
  selectedItemIds: string[]
  onSelectionChange: (itemIds: string[], items: ContentItem[]) => void
  renderLabel: string
  messages?: FormMessage[]
  isRequired?: boolean
}

const MINIMUM_SEARCH_LENGTH = 2

function liveRegion(): HTMLElement {
  const div = document.getElementById('flash_screenreader_holder')
  if (!(div instanceof HTMLElement)) {
    throw new Error('live region not found')
  }
  return div
}

export default function ModuleItemMultiSelect({
  itemType,
  courseId,
  selectedItemIds,
  onSelectionChange,
  renderLabel,
  messages = [],
  isRequired = false,
}: ModuleItemMultiSelectProps) {
  const [selectedItems, setSelectedItems] = useState<ContentItem[]>([])
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [inputValue, setInputValue] = useState('')
  const [announcement, setAnnouncement] = useState<string>('')

  const inputRef = useRef<HTMLInputElement | null>(null)
  const searchInputRef = useRef<HTMLInputElement | null>(null)

  const isSearchableTerm = useCallback(
    (term: string) => term.length === 0 || term.length >= MINIMUM_SEARCH_LENGTH,
    [],
  )

  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    timeout: 750,
    isSearchableTerm,
  })

  const {data, isLoading, isError, hasNextPage, fetchNextPage, isFetchingNextPage} =
    useModuleItemContent(
      itemType,
      courseId,
      searchTerm,
      searchTerm.length >= MINIMUM_SEARCH_LENGTH || searchTerm.length === 0,
    )

  const allItems = useMemo(() => {
    return data?.pages?.flatMap(page => page.items) || []
  }, [data?.pages])

  useEffect(() => {
    if (allItems.length > 0 && selectedItemIds.length > 0) {
      const items = allItems.filter(item => selectedItemIds.includes(item.id))
      if (items.length > 0) {
        setSelectedItems(prevItems => {
          const existingIds = new Set(prevItems.map(i => i.id))
          const newItems = items.filter(i => !existingIds.has(i.id))
          return newItems.length > 0 ? [...prevItems, ...newItems] : prevItems
        })
      }
    }
  }, [allItems, selectedItemIds])

  useEffect(() => {
    const availableItems = allItems.filter(item => !selectedItemIds.includes(item.id))
    if (availableItems.length === 0 && hasNextPage && !isFetchingNextPage && !isLoading) {
      fetchNextPage()
    }
  }, [allItems, selectedItemIds, hasNextPage, isFetchingNextPage, isLoading, fetchNextPage])

  const handleRequestShowOptions = useCallback(() => {
    setIsShowingOptions(true)
  }, [])

  const handleRequestHideOptions = useCallback(() => {
    setIsShowingOptions(false)
    setInputValue('')
    setSearchTerm('')
    setAnnouncement(I18n.t('List collapsed'))
  }, [setSearchTerm])

  const handleRequestHighlightOption = useCallback(
    (_event: React.SyntheticEvent, {id}: {id?: string}) => {
      if (!id) return
      const item = allItems.find(item => item.id === id)
      if (item) {
        setHighlightedOptionId(id)
        setAnnouncement(item.name)
      }
    },
    [allItems],
  )

  const handleRequestSelectOption = useCallback(
    (_event: React.SyntheticEvent, {id}: {id?: string}) => {
      if (!id) return

      const item = allItems.find(item => item.id === id)
      if (!item) return

      if (selectedItemIds.includes(id)) return

      const newSelectedIds = [...selectedItemIds, id]
      const newSelectedItems = [...selectedItems, item]

      setSelectedItems(newSelectedItems)
      setIsShowingOptions(true)
      setAnnouncement(I18n.t('%{name} selected', {name: item.name}))
      onSelectionChange(newSelectedIds, newSelectedItems)

      setTimeout(() => inputRef.current?.focus(), 0)
    },
    [allItems, selectedItemIds, selectedItems, onSelectionChange],
  )

  const handleInputChange = useCallback(
    (event: React.FormEvent<HTMLInputElement>) => {
      const target = event.target as HTMLInputElement
      const newValue = target.value
      setInputValue(newValue)
      setSearchTerm(newValue)
    },
    [setSearchTerm],
  )

  const handleDismissTag = useCallback(
    (itemId: string, itemName: string) => {
      const newSelectedIds = selectedItemIds.filter(id => id !== itemId)
      const newSelectedItems = selectedItems.filter(item => item.id !== itemId)

      setSelectedItems(newSelectedItems)
      setAnnouncement(I18n.t('%{name} removed', {name: itemName}))
      onSelectionChange(newSelectedIds, newSelectedItems)
    },
    [selectedItemIds, selectedItems, onSelectionChange],
  )

  const renderTags = () => {
    return selectedItems.map(item => (
      <Tag
        key={item.id}
        dismissible={true}
        text={item.name}
        title={I18n.t('Remove %{name}', {name: item.name})}
        margin="0 xxx-small"
        onClick={(e: React.MouseEvent) => {
          e.stopPropagation()
          e.preventDefault()
          handleDismissTag(item.id, item.name)
        }}
      />
    ))
  }

  const renderOptions = () => {
    const actuallyLoading = isLoading || searchTermIsPending

    if (isError) {
      return (
        <Select.Option id="error" isHighlighted={false} isSelected={false}>
          {I18n.t('Error loading content')}
        </Select.Option>
      )
    }

    if (actuallyLoading) {
      return (
        <Select.Option id="loading" isHighlighted={false} isSelected={false}>
          <Spinner renderTitle={I18n.t('Loading options...')} size="x-small" />
        </Select.Option>
      )
    }

    if (searchTerm.length > 0 && searchTerm.length < MINIMUM_SEARCH_LENGTH) {
      return (
        <Select.Option id="min-length" isHighlighted={false} isSelected={false}>
          {I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH})}
        </Select.Option>
      )
    }

    const availableItems = allItems.filter(item => !selectedItemIds.includes(item.id))

    if (availableItems.length === 0 && !hasNextPage) {
      return (
        <Select.Option id="no-options" isHighlighted={false} isSelected={false}>
          {I18n.t('No items found')}
        </Select.Option>
      )
    }

    if (availableItems.length === 0 && hasNextPage && !isFetchingNextPage) {
      return (
        <Select.Option id="loading" isHighlighted={false} isSelected={false}>
          <Spinner renderTitle={I18n.t('Loading more options...')} size="x-small" />
        </Select.Option>
      )
    }

    const hasGroups = availableItems.some(item => item.groupId && item.groupName)

    if (hasGroups) {
      const groupedItems = availableItems.reduce(
        (acc, item) => {
          const groupId = item.groupId || 'no-group'
          const groupName = item.groupName || I18n.t('No Group')
          if (!acc[groupId]) {
            acc[groupId] = {groupName, items: []}
          }
          acc[groupId].items.push(item)
          return acc
        },
        {} as Record<string, {groupName: string; items: ContentItem[]}>,
      )

      return Object.entries(groupedItems).map(([groupId, {groupName, items}]) => (
        <Select.Group key={groupId} renderLabel={groupName}>
          {items.map(item => (
            <Select.Option
              key={item.id}
              id={item.id}
              isHighlighted={item.id === highlightedOptionId}
              isSelected={false}
            >
              {item.name}
            </Select.Option>
          ))}
        </Select.Group>
      ))
    }

    return availableItems.map(item => (
      <Select.Option
        key={item.id}
        id={item.id}
        isHighlighted={item.id === highlightedOptionId}
        isSelected={false}
      >
        {item.name}
      </Select.Option>
    ))
  }

  return (
    <>
      <Select
        data-testid="add-item-content-select"
        renderLabel={renderLabel}
        assistiveText={I18n.t('Click to open, or start typing to search for an option.')}
        placeholder={I18n.t('Click to open, or start typing to search for an option.')}
        isShowingOptions={isShowingOptions}
        inputValue={inputValue}
        inputRef={ref => {
          inputRef.current = ref
        }}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleRequestShowOptions}
        onRequestHideOptions={handleRequestHideOptions}
        onRequestHighlightOption={handleRequestHighlightOption}
        onRequestSelectOption={handleRequestSelectOption}
        renderBeforeInput={selectedItems.length > 0 ? renderTags() : null}
        messages={messages}
        isRequired={isRequired && selectedItemIds.length === 0}
      >
        {renderOptions()}
      </Select>
      {announcement && (
        <Alert liveRegion={liveRegion} liveRegionPoliteness="assertive" screenReaderOnly={true}>
          {announcement}
        </Alert>
      )}
    </>
  )
}

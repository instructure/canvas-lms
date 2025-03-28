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
import React, {
  useState,
  useCallback,
  useEffect,
  useMemo,
  type SyntheticEvent
} from 'react'
import { SimpleSelect } from '@instructure/ui-simple-select'
import { Select } from '@instructure/ui-select'
import { IconSearchLine } from '@instructure/ui-icons'
import { useScope as createI18nScope } from '@canvas/i18n'
import type { FormMessage } from '@instructure/ui-form-field'

const I18n = createI18nScope('content_copy_redesign')

type Option = {
  id: string
  name: string
  disabled?: boolean
  startAt?: string | null
  endAt?: string | null
}

type GroupedOptions = Record<string, Option[]>

export const ConfiguredSelectInput = ({
  label,
  defaultInputValue = '',
  options,
  onSelect,
  disabled = false,
  messages = [],
  searchable = false
}: {
  label: string
  defaultInputValue?: string
  options: Array<Option>
  onSelect: (selectedId: string | null) => void
  disabled?: boolean
  messages?: Array<FormMessage>
  searchable?: boolean
}) => {
  const [inputValue, setInputValue] = useState<string>(defaultInputValue)
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null)
  const [filteredFlatOptions, setFilteredFlatOptions] = useState<Option[]>(options)
  const [shouldFilter, setShouldFilter] = useState(false)

  const groupOptionsByDate = useCallback((options: Option[]): GroupedOptions => {
    const now = new Date()
    const grouped: GroupedOptions = {
      Active: [],
      Future: [],
      Past: [],
      Unscheduled: []
    }

    options.forEach(option => {
      const start = option.startAt ? new Date(option.startAt) : null
      const end = option.endAt ? new Date(option.endAt) : null

      if (start && end && now >= start && now <= end) {
        grouped.Active.push(option)
      } else if (start && now < start) {
        grouped.Future.push(option)
      } else if (end && now > end) {
        grouped.Past.push(option)
      } else {
        grouped.Unscheduled.push(option)
      }
    })

    return grouped
  }, [])

  const groupedOptions = useMemo(
    () => groupOptionsByDate(filteredFlatOptions),
    [filteredFlatOptions, groupOptionsByDate]
  )

  const filterOptions = useCallback(
    (value: string) => {
      const lower = value.toLowerCase()
      return options.filter(option =>
        option.name.toLowerCase().includes(lower)
      )
    },
    [options]
  )

  const getOptionById = useCallback(
    (id: string) => filteredFlatOptions.find(opt => opt.id === id),
    [filteredFlatOptions]
  )

  useEffect(() => {
    if (!shouldFilter) {
      return
    }
    else if (!inputValue) {
      setFilteredFlatOptions(options)
    } else {
      const filtered = filterOptions(inputValue)
      setFilteredFlatOptions(filtered)
      setHighlightedOptionId(filtered.length > 0 ? filtered[0].id : null)
    }
  }, [inputValue, options, filterOptions])

  useEffect(() => {
    if (!defaultInputValue && searchable) {
      const firstOption = Object.values(groupedOptions).flat()[0]
      if (firstOption) {
        setInputValue(firstOption.name)
        setSelectedOptionId(firstOption.id)
        onSelect(firstOption.id)
      }
    }
  }, [defaultInputValue, searchable, groupedOptions])

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value)
    setIsShowingOptions(true)
    setShouldFilter(true)
  }

  const handleShowOptions = () => setIsShowingOptions(true)

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
  }

  const handleSelectOption = (_: SyntheticEvent, { id }: { id?: string }) => {
    const selected = id ? getOptionById(id) : null
    if (!selected) return
    setSelectedOptionId(selected.id)
    setInputValue(selected.name)
    setShouldFilter(false)
    setFilteredFlatOptions(options)
    setIsShowingOptions(false)
    onSelect(selected.id)
  }

  const handleHighlightOption = (event: SyntheticEvent, { id }: { id?: string }) => {
    event.persist()
    if (!id) {
      setHighlightedOptionId(null)
      return
    }
    setHighlightedOptionId(id)
  }

  if (!searchable) {
    return (
      <SimpleSelect
        renderLabel={label}
        assistiveText={I18n.t('Use arrow keys to navigate options.')}
        value={inputValue}
        defaultValue={inputValue}
        onChange={(_: SyntheticEvent, { id, value }) => {
          const convertedId = id === undefined ? null : id
          setInputValue(value as string)
          onSelect(convertedId)
        }}
        interaction={disabled ? 'disabled' : 'enabled'}
        messages={messages}
      >
        {options.map(option => (
          <SimpleSelect.Option
            key={option.id}
            id={option.id}
            value={option.name}
          >
            {option.name}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    )
  }

  return (
    <div>
      <Select
        renderLabel={label}
        assistiveText={I18n.t('Type to navigate options.')}
        placeholder={I18n.t('Start typing to search...')}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        onBlur={() => setHighlightedOptionId(null)}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestSelectOption={handleSelectOption}
        onRequestHighlightOption={handleHighlightOption}
        interaction={disabled ? 'disabled' : 'enabled'}
        messages={messages}
        renderAfterInput={<IconSearchLine inline={false} />}
      >
        {
          filteredFlatOptions.length > 0 ? (
            Object.entries(groupedOptions)
              .filter(([, options]) => options.length > 0)
              .map(([group, options]) => (
                <Select.Group key={group} renderLabel={group}>
                  {options.map(option => (
                    <Select.Option
                      key={option.id}
                      id={option.id}
                      isHighlighted={option.id === highlightedOptionId}
                      isSelected={option.id === selectedOptionId}
                      isDisabled={option.disabled}
                    >
                      {option.name}
                    </Select.Option>
                  ))}
                </Select.Group>
              ))
          ) : (
            <Select.Option id="empty-option" key="empty-option">
              {I18n.t('No results')}
            </Select.Option>
          )
        }
      </Select>
    </div>
  )
}

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

import React, {forwardRef, useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {closedCaptionLanguages} from '@instructure/canvas-media'
import {Select} from '@instructure/ui-select'
import {colors, spacing} from '@instructure/canvas-theme'
import {IconAddLine, IconSearchLine} from '@instructure/ui-icons'

const I18n = createI18nScope('files_v2')

const getOptions = (existingLocales: string[]) => {
  const availableOptions: Option[] = closedCaptionLanguages.filter(
    option => !existingLocales.includes(option.id),
  )
  const englishOption = availableOptions.find(opt => opt.id === 'en')
  const otherOptions = availableOptions
    .filter(opt => opt.id !== 'en')
    .sort((a, b) => a.label.localeCompare(b.label))
  return englishOption ? [englishOption, ...otherOptions] : otherOptions
}

interface Option {
  id: string
  label: string
}

export interface LanguageSelectorProps {
  locale: string | null
  handleLocaleChange: (locale: string | null) => void
  existingLocales?: string[]
  localeError: string
}

export const LanguageSelector = forwardRef<Select, LanguageSelectorProps>(function LanguageSelector(
  {locale, handleLocaleChange, existingLocales = [], localeError}: LanguageSelectorProps,
  ref,
) {
  const options = useMemo(() => getOptions(existingLocales), [existingLocales])
  const [inputValue, setInputValue] = useState<string>('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [filteredOptions, setFilteredOptions] = useState<Option[]>(options)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(
    filteredOptions[0]?.id ?? null,
  )

  const filterOptions = (value: string): Option[] =>
    options.filter(option => option.label.toLowerCase().startsWith(value.toLowerCase()))

  const onInputChange = (e: React.ChangeEvent<HTMLInputElement>): void => {
    const value = e.target.value
    setInputValue(value)
    const newFilteredOptions = filterOptions(value)
    setFilteredOptions(newFilteredOptions)
    setHighlightedOptionId(newFilteredOptions[0]?.id ?? null)
    setIsShowingOptions(true)
    if (value === '') {
      handleLocaleChange(null)
    }
  }

  const onBlur = (_e: React.ChangeEvent<HTMLInputElement>): void => {
    setIsShowingOptions(false)
  }

  const onSelectOption = (id: string): void => {
    const option = options.find(opt => opt.id === id)
    if (!option) return
    handleLocaleChange(id)
    setIsShowingOptions(false)
    setInputValue(option.label)
    setFilteredOptions(options)
    setHighlightedOptionId(options[0].id)
  }

  return (
    <Select
      renderLabel={
        <p style={{color: colors.primitives.white, marginTop: spacing.small}}>
          {I18n.t('Choose a language')}
          <span style={{color: localeError ? colors.ui.textError : colors.primitives.white}}>
            *
          </span>
        </p>
      }
      assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
      placeholder={I18n.t('Start typing to search...')}
      inputValue={inputValue}
      messages={localeError ? [{type: 'newError', text: localeError}] : []}
      // inputRef={element => {
      // }}
      ref={ref}
      isShowingOptions={isShowingOptions}
      onInputChange={onInputChange}
      onBlur={onBlur}
      onRequestHideOptions={() => {
        setIsShowingOptions(false)
        setHighlightedOptionId(null)
      }}
      onRequestShowOptions={() => {
        setIsShowingOptions(true)
      }}
      onRequestSelectOption={(_e, {id}: {id?: string | undefined}) => {
        onSelectOption(id as string)
      }}
      onRequestHighlightOption={(_e, {id}) => {
        setHighlightedOptionId(id ? id : null)
      }}
      renderBeforeInput={<IconAddLine inline={false} />}
      renderAfterInput={<IconSearchLine inline={false} />}
    >
      {filteredOptions.length > 0 ? (
        filteredOptions.map(option => (
          <Select.Option
            id={option.id}
            key={option.id}
            isHighlighted={option.id === highlightedOptionId}
            isSelected={option.id === locale}
          >
            {option.label}
          </Select.Option>
        ))
      ) : (
        <Select.Option id="empty-option" key="empty-option">
          {I18n.t('No matching options found.')}
        </Select.Option>
      )}
    </Select>
  )
})

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
import React, {useState} from 'react'
import {bool, func, array, string} from 'prop-types'
import CanvasAsyncSelect from '../../shared/components/CanvasAsyncSelect'

SearchableSelect.propTypes = {
  options: array.isRequired,
  isLoading: bool,
  onChange: func.isRequired,
  label: string
}

SearchableSelect.defaultProps = {
  isLoading: false
}

export default function SearchableSelect({options, isLoading, onChange, label}) {
  const [inputValue, setInputValue] = useState('')
  const [matcher, setMatcher] = useState(new RegExp(''))
  const [selectedItemId, setSelectedItemId] = useState(null)

  const inputLength = inputValue.length
  const noOptionsLabel =
    inputLength === 0 ? I18n.t('No results') : I18n.t('No matches to your search')

  function onInputChange(e) {
    setInputValue(e.target.value)
    setMatcher(new RegExp('^(\\s*)' + e.target.value, 'i'))
    setSelectedItemId(null)
  }

  function onOptionSelected(e, id) {
    setInputValue(options.find(i => i.id === id).name)
    setMatcher(new RegExp(''))
    setSelectedItemId(id)
    onChange(e, id)
  }

  function onBlur(e) {
    const possibleSelection = options.filter(i => i.name.match(matcher))
    if (possibleSelection.length === 1) onOptionSelected(e, possibleSelection[0].id)
  }

  const renderFilteredItems = items =>
    items
      .filter(i => i.name.match(matcher))
      .map(item => (
        <CanvasAsyncSelect.Option key={`${label}-${item.id}`} id={item.id}>
          {item.name}
        </CanvasAsyncSelect.Option>
      ))

  const props = {
    isLoading,
    selectedOptionId: selectedItemId,
    inputValue,
    assistiveText: I18n.t('Enter text to search'),
    renderLabel: () => label,
    placeholder: I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange,
    onOptionSelected,
    onBlur
  }
  return <CanvasAsyncSelect {...props}>{renderFilteredItems(options)}</CanvasAsyncSelect>
}

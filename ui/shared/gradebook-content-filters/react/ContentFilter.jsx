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

import React, {useState} from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'

import natcompare from '@canvas/util/natcompare'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook_default_gradebook_components_content_filters_content_filter')

function renderItem(option, {disabled, highlightedItemId, selectedItemId}) {
  return (
    <Select.Option
      isDisabled={disabled && selectedItemId !== option.id}
      id={option.id}
      isHighlighted={option.id === highlightedItemId}
      isSelected={option.id === selectedItemId}
      key={option.id}
    >
      {option.name}
    </Select.Option>
  )
}

function renderItemAndChildren(option, state) {
  return (
    <Select.Group renderLabel={option.name} key={`group_${option.id}`}>
      {option.children.map(child => renderItem(child, state))}
    </Select.Group>
  )
}

function findSelectedItem(selectedItemId, items) {
  for (const item of items) {
    if (item.id === selectedItemId) {
      return item
    }

    if (item.children && item.children.length) {
      const found = findSelectedItem(selectedItemId, item.children)
      if (found) {
        return found
      }
    }
  }

  return null
}

export default function ContentFilter(props) {
  const {allItemsId, allItemsLabel, disabled, label, items, selectedItemId} = props

  const [highlightedItemId, setHighlightedItemId] = useState(selectedItemId)
  const [isShowingOptions, setIsShowingOptions] = useState(false)

  let selectedItemLabel = allItemsLabel
  const selectedItem = findSelectedItem(selectedItemId, items)
  if (selectedItem != null) {
    selectedItemLabel = selectedItem.name
  }

  function handleHighlightOption(_event, {id}) {
    setHighlightedItemId(id)
  }

  function handleSelectOption(_event, {id}) {
    setIsShowingOptions(false)
    if (!disabled && id !== selectedItemId) {
      props.onSelect(id)
    }
  }

  let options = [{id: allItemsId, name: allItemsLabel}]
  if (props.sortAlphabetically) {
    options = options.concat(items.sort(natcompare.byKey('name')))
  } else {
    options = options.concat(items)
  }

  return (
    <Select
      assistiveText={I18n.t('Use arrow keys to navigate options.')}
      inputValue={selectedItemLabel}
      isInline={true}
      isShowingOptions={isShowingOptions}
      onRequestHideOptions={() => setIsShowingOptions(false)}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelectOption}
      onRequestShowOptions={() => setIsShowingOptions(true)}
      renderLabel={<ScreenReaderContent>{label}</ScreenReaderContent>}
    >
      {options.map(option => {
        const renderFn = option.children ? renderItemAndChildren : renderItem
        return renderFn(option, {disabled, highlightedItemId, selectedItemId})
      })}
    </Select>
  )
}

ContentFilter.propTypes = {
  allItemsId: string.isRequired,
  allItemsLabel: string.isRequired,
  disabled: bool.isRequired,
  label: string.isRequired,

  items: arrayOf(
    shape({
      /* groups can only ever be a single level deep */
      children: arrayOf(
        shape({
          id: string.isRequired,
          name: string.isRequired,
        })
      ),

      id: string.isRequired,
      name: string.isRequired,
    })
  ).isRequired,

  onSelect: func.isRequired,
  selectedItemId: string,
  sortAlphabetically: bool,
}

ContentFilter.defaultProps = {
  selectedItemId: null,
  sortAlphabetically: false,
}

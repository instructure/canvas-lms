// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import CanvasMultiSelect from '@canvas/multi-select'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

type Props = {
  id: string
  label: string
  'data-testid'?: string
  customMatcher?: (option: {label: string; id: string}, query: string) => boolean
  disabled: boolean
  options: Array<{id: string; text: string}>
  onChange: (optionIds: string[]) => void
  placeholder: string
}

function MultiSelectSearchInput(props: Props) {
  const [selectedOptionIds, setSelectedOptionIds] = useState<string[]>([])

  const handleInputChange = (optionIds: string[]) => {
    setSelectedOptionIds(optionIds)
    props.onChange(optionIds)
  }

  return (
    <View as="div" textAlign="start" margin="0 0 small 0">
      <CanvasMultiSelect
        data-testid={props['data-testid']}
        id={props.id}
        label={props.label}
        selectedOptionIds={selectedOptionIds}
        disabled={props.disabled}
        onChange={handleInputChange}
        placeholder={props.placeholder}
        customRenderBeforeInput={tags => [<IconSearchLine key="search-icon" />].concat(tags || [])}
        customMatcher={props.customMatcher}
      >
        {props.options.map(option => (
          <CanvasMultiSelectOption id={option.id} key={option.id} value={option.id}>
            {option.text}
          </CanvasMultiSelectOption>
        ))}
      </CanvasMultiSelect>
    </View>
  )
}

MultiSelectSearchInput.defaultProps = {
  customMatcher: null,
}

export default MultiSelectSearchInput

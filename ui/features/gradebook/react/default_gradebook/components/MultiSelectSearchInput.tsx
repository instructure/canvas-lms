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
import PropTypes from 'prop-types'

function MultiSelectSearchInput(props) {
  const [selectedOptionIds, setSelectedOptionIds] = useState([])

  const handleInputChange = optionIds => {
    setSelectedOptionIds(optionIds)
    props.onChange(optionIds)
  }

  return (
    <View as="div" textAlign="start" margin="0 0 small 0">
      <CanvasMultiSelect
        data-testid={props['data-test-id']}
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
          <CanvasMultiSelect.Option id={option.id} key={option.id} value={option.id}>
            {option.text}
          </CanvasMultiSelect.Option>
        ))}
      </CanvasMultiSelect>
    </View>
  )
}

MultiSelectSearchInput.propTypes = {
  id: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  'data-test-id': PropTypes.string,
  customMatcher: PropTypes.func,
  disabled: PropTypes.bool.isRequired,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      text: PropTypes.string.isRequired,
    })
  ).isRequired,
  onChange: PropTypes.func.isRequired,
  placeholder: PropTypes.string.isRequired,
}

MultiSelectSearchInput.defaultProps = {
  customMatcher: null,
}

export default MultiSelectSearchInput

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
import I18n from 'i18n!gradebook'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import PropTypes from 'prop-types'

function TextSearchInput({label, readonly = false, onChange}) {
  const [inputValue, setInputValue] = useState('')

  const handleInputChange = event => {
    const query = event.target.value
    setInputValue(query)
    onChange(query)
  }

  return (
    <View as="div" textAlign="start" margin="0 0 small 0">
      <TextInput
        renderLabel={label}
        value={inputValue}
        onChange={handleInputChange}
        interaction={readonly ? 'readonly' : 'enabled'}
        renderBeforeInput={<IconSearchLine inline={false} />}
      />
    </View>
  )
}

TextSearchInput.propTypes = {
  label: PropTypes.string.isRequired,
  readonly: PropTypes.bool,
  onChange: PropTypes.func.isRequired
}

export default TextSearchInput

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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field/types/FormPropTypes'
import {IconWarningSolid} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('editGroup')

export type GroupSetNameInputProps = {
  id: string,
  initialValue?: string,
  getShouldShowEmptyNameError?: () => boolean,
  setShouldShowEmptyNameError?: (shouldShow: boolean) => void,
}

const GroupSetNameInput = ({
  id,
  initialValue = '',
  getShouldShowEmptyNameError,
  setShouldShowEmptyNameError,
}: GroupSetNameInputProps) => {
  const [nameValue, setNameValue] = useState<string>(initialValue)
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])

  const handleFocus = (_event: React.FocusEvent<HTMLInputElement>) => {
    if (getShouldShowEmptyNameError && getShouldShowEmptyNameError()) {
      // reset the value
      if (setShouldShowEmptyNameError) setShouldShowEmptyNameError(false)
      const errorText = I18n.t('Name is required')
      setErrorMessages([{ text: errorText, type: 'newError' }])
    }
  }

  const validateInput = (_event: React.FocusEvent<HTMLInputElement>) => {
    if (nameValue) {
      let errorText
      if (nameValue.length > 255) {
        errorText = I18n.t('Name must be 255 characters or less')
      }
      if (errorText) setErrorMessages([{ text: errorText, type: 'newError' }])
    }
  }

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setErrorMessages([])
    setNameValue(value)
  }

  return (
    <View as='div' margin='small xx-small'>
      <TextInput
        id={`category_${id}_name`}
        renderLabel=""
        messages={errorMessages}
        name='name'
        value={nameValue}
        onFocus={handleFocus}
        onBlur={validateInput}
        onChange={handleInputChange}
        width='250px'
        data-testid={`category_${id}_name`}
      />
    </View>
  )
}

export default GroupSetNameInput

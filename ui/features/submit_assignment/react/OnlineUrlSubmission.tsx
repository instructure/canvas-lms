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
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import type {FormMessage} from '@instructure/ui-form-field'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('submit_online_url_assignment')

const OnlineUrlSubmission = ({
  setValue,
  getShouldShowUrlError,
  setShouldShowUrlError,
}: {
  setValue: (value: string) => void
  getShouldShowUrlError: () => boolean
  setShouldShowUrlError: (value: boolean) => void
}) => {
  const [input, setInput] = useState('')
  const [onlineUrlErrors, setOnlineUrlErrors] = useState<FormMessage[]>([])

  const clearErrors = () => {
    setOnlineUrlErrors([])
  }

  const showErrors = () => {
    const errorMessage = I18n.t('A valid URL is required')
    setOnlineUrlErrors([
      {
        type: 'newError',
        text: errorMessage,
      },
    ])
    // reset the value
    setShouldShowUrlError(false)
  }

  const handleInputChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setInput(value)
    setValue(value)
    clearErrors()
  }

  const handleFocus = () => {
    if (getShouldShowUrlError()) {
      showErrors()
    }
  }

  const handleBlur = () => {
    if (!input) {
      clearErrors()
    }
  }

  const label = (
    <>
      <Text>{I18n.t('Website URL')}</Text>
      <Text color={onlineUrlErrors.length > 0 ? "danger" : "primary"}>*</Text>
    </>
  )

  return (
    <Flex as="div" margin="0 0 small 0">
      <TextInput
        id="online-url-input"
        renderLabel={label}
        placeholder="https://"
        messages={onlineUrlErrors}
        onChange={handleInputChange}
        onBlur={handleBlur}
        onFocus={handleFocus}
        data-testid="online-url-input"
      />
    </Flex>
  )
}

export default OnlineUrlSubmission

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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {datetimeString} from '@canvas/datetime/date-functions'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ErrorFormMessage} from '@canvas/content-migrations'
import type {FormMessage} from '@instructure/ui-form-field'

export const ConfiguredDateInput = ({
  selectedDate,
  placeholder,
  renderScreenReaderLabelText,
  renderLabelText,
  onSelectedDateChange,
  timeZone,
  disabled = false,
  errorMessage,
}: {
  selectedDate?: string | null
  placeholder?: string
  renderScreenReaderLabelText: string
  renderLabelText: string
  onSelectedDateChange: (d: Date | null) => void
  timeZone?: string
  disabled?: boolean
  errorMessage?: string
}) => {
  const formatDate = (date: Date) => {
    return datetimeString(date, {timezone: timeZone})
  }

  const generateErrorMessage = (message: string): FormMessage[] => {
    return [
      {
        text: <ErrorFormMessage>{message}</ErrorFormMessage>,
        type: 'error',
      },
    ]
  }

  return (
    <>
      <Text weight="bold">{renderLabelText}</Text>
      <Flex as="div" padding="xx-small 0 0 0" direction="column">
        <CanvasDateInput
          selectedDate={selectedDate}
          onSelectedDateChange={onSelectedDateChange}
          formatDate={formatDate}
          placeholder={placeholder}
          renderLabel={<ScreenReaderContent>{renderScreenReaderLabelText}</ScreenReaderContent>}
          interaction={disabled ? 'disabled' : 'enabled'}
          width="100%"
          messages={errorMessage ? generateErrorMessage(errorMessage) : []}
        />
      </Flex>
    </>
  )
}

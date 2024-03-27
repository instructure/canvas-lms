/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {NumberInput} from '@instructure/ui-number-input'
import type {FormMessage} from '@instructure/ui-form-field'

type Props = {
  numberInput: number
  setNumberInput: (points: number) => void
  numberInputLabel: string
  numberInputDataTestId: string
  messages?: FormMessage[]
  setRef?: (ref: HTMLInputElement | null) => void
}

export const DiscussionTopicNumberInput = ({
  numberInput,
  setNumberInput,
  numberInputLabel,
  numberInputDataTestId,
  messages,
  setRef,
}: Props) => {
  return (
    <NumberInput
      data-testid={numberInputDataTestId}
      renderLabel={numberInputLabel}
      onIncrement={() => setNumberInput(Math.max(0, numberInput + 1))}
      onDecrement={() => setNumberInput(Math.max(0, numberInput - 1))}
      value={numberInput.toString()}
      onChange={event => {
        // don't allow non-numeric values
        if (!/^\d*\.?\d*$/.test(event.target.value)) return
        const value = parseInt(event.target.value, 10)
        setNumberInput(Number.isNaN(value) ? 0 : value)
      }}
      messages={messages || []}
      inputRef={setRef}
    />
  )
}

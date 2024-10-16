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
import numberHelper from '@canvas/i18n/numberHelper'

type Props = {
  pointsPossible: number
  setPointsPossible: (points: string | number) => void
  pointsPossibleLabel: string
  pointsPossibleDataTestId: string
}

export const PointsPossible = ({
  pointsPossible,
  setPointsPossible,
  pointsPossibleLabel,
  pointsPossibleDataTestId,
}: Props) => {
  return (
    <NumberInput
      allowStringValue={true}
      inputMode="decimal"
      showArrows={false}
      data-testid={pointsPossibleDataTestId}
      renderLabel={pointsPossibleLabel}
      value={pointsPossible}
      onBlur={event => {
        const value = numberHelper.parse(event.target.value)
        if (value) {
          // cut off any decimal places beyond 2 and re-parse
          setPointsPossible(Number.isInteger(value) ? value : numberHelper.parse(value.toFixed(2)))
        } else {
          // default to 0 if the value is invalid
          setPointsPossible(0)
        }
      }}
      onChange={event => {
        // don't allow non-numeric values
        const value = event.target.value
        if (!/^\d*\.?\d*$/.test(value)) return
        setPointsPossible(value)
      }}
    />
  )
}

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
import {useScope as useI18nScope} from '@canvas/i18n'

import {NumberInput} from '@instructure/ui-number-input'

const I18n = useI18nScope('discussion_create')

type Props = {
  pointsPossible: number
  setPointsPossible: (points: number) => void
}

export const PointsPossible = ({pointsPossible, setPointsPossible}: Props) => {
  return (
    <NumberInput
      data-testid="points-possible-input"
      renderLabel={I18n.t('Points Possible')}
      onIncrement={() => setPointsPossible(Math.max(0, pointsPossible + 1))}
      onDecrement={() => setPointsPossible(Math.max(0, pointsPossible - 1))}
      value={pointsPossible.toString()}
      onChange={event => {
        // don't allow non-numeric values
        if (!/^\d*\.?\d*$/.test(event.target.value)) return
        setPointsPossible(Number.parseInt(event.target.value, 10))
      }}
    />
  )
}

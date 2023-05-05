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

import React, {useCallback} from 'react'
import {uid} from '@instructure/uid'

import {BlackoutDate} from '../types'
import {BlackoutDatesTable} from './blackout_dates_table'
import NewBlackoutDatesForm from './new_blackout_dates_form'

interface PassedProps {
  readonly blackoutDates: BlackoutDate[]
  readonly onChange: (blackoutDates: BlackoutDate[]) => any
}

const BlackoutDates = ({blackoutDates, onChange}: PassedProps) => {
  const addBlackoutDate = useCallback(
    (blackoutDate: BlackoutDate) => {
      blackoutDate.temp_id = uid('temp_', 3)
      onChange(blackoutDates.concat([blackoutDate]))
    },
    [blackoutDates, onChange]
  )

  const deleteBlackoutDate = useCallback(
    (blackoutDate: BlackoutDate) => {
      const newBlackoutDates: BlackoutDate[] = blackoutDates.filter(
        (bod: BlackoutDate) =>
          (bod.id && bod.id !== blackoutDate.id) || bod.temp_id !== blackoutDate.temp_id
      )
      onChange(newBlackoutDates)
    },
    [blackoutDates, onChange]
  )

  return (
    <div>
      <NewBlackoutDatesForm addBlackoutDate={addBlackoutDate} />
      <BlackoutDatesTable
        displayType="course"
        blackoutDates={blackoutDates}
        deleteBlackoutDate={deleteBlackoutDate}
      />
    </div>
  )
}

export default BlackoutDates

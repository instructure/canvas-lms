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

import React from 'react'
import { screen, fireEvent } from '@testing-library/react'
import {renderConnected} from '../../../__tests__/utils'
import '@testing-library/jest-dom'
import TimeSelection from '../TimeSelection'
import { PRIMARY_PACE, STUDENT_PACE } from '../../../__tests__/fixtures'
import { CoursePace, Pace } from 'features/course_paces/react/types'
import keycode from 'keycode'

const responsiveSize = 'small'

const appliedPace: Pace = {
  name: 'LS3432',
  type: 'Course',
  duration: 6,
  last_modified: '2022-10-17T23:12:24Z',
}

const coursePace: CoursePace = {
  ...PRIMARY_PACE,
  start_date: '2021-09-01',
  time_to_complete_calendar_days: 90,
}

describe('Pace Modal TimeSelection', () => {
  it('displays the correct start date', () => {
    renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    expect(screen.getByLabelText('Start Date')).toHaveValue('September 1, 2021')
  })

  it('displays the correct end date from PRIMARY_PACE.end_date', () => {
    renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    expect(screen.getByLabelText('End Date')).toHaveValue('November 30, 2021')
  })

  it('updates the end date when incrementing weeks', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const weeksInput = getByTestId('weeks-number-input')
    fireEvent.keyDown(weeksInput, { keyCode: keycode.codes.up })

    expect(screen.getByLabelText('End Date')).toHaveValue('December 7, 2021')
  })

  it('updates the end date when decrementing weeks', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const weeksInput = getByTestId('weeks-number-input')
    fireEvent.keyDown(weeksInput, { keyCode: keycode.codes.down })

    expect(screen.getByLabelText('End Date')).toHaveValue('November 23, 2021')
  })

  it('updates the end date when incrementing days', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const weeksInput = getByTestId('days-number-input')
    fireEvent.keyDown(weeksInput, { keyCode: keycode.codes.up })

    expect(screen.getByLabelText('End Date')).toHaveValue('December 1, 2021')
  })

  it('updates the end date when decrementing days', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const weeksInput = getByTestId('days-number-input')
    fireEvent.keyDown(weeksInput, { keyCode: keycode.codes.down })

    expect(screen.getByLabelText('End Date')).toHaveValue('November 29, 2021')
  })

  it('updates time to complete when start date is changed', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const dateText = '2021-09-16'
    const startDateInput = getByTestId('start-date-input')

    fireEvent.change(startDateInput, { target: { value: dateText } })
    fireEvent.blur(startDateInput)

    const weeksInput = getByTestId('weeks-number-input')

    expect(weeksInput).toHaveValue(10)
  })

  it('updates time to complete when end date is changed', () => {
    const { getByTestId } = renderConnected(
      <TimeSelection
        coursePace={coursePace}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )
    const dateText = '2021-12-23'
    const endDateInput = getByTestId('end-date-input')

    fireEvent.change(endDateInput, { target: { value: dateText } })
    fireEvent.blur(endDateInput)

    const weeksInput = getByTestId('weeks-number-input')

    expect(weeksInput).toHaveValue(16)
  })

  it('Start date input is not available for Student Pace', () => {
    const { queryByTestId } = renderConnected(
      <TimeSelection
        coursePace={STUDENT_PACE}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )

    const startDateInput = queryByTestId('start-date-input')

    expect(startDateInput).not.toBeInTheDocument()
  })

  it('Start date Label is shown for Student Pace', () => {
    const { queryByTestId } = renderConnected(
      <TimeSelection
        coursePace={STUDENT_PACE}
        appliedPace={appliedPace}
        responsiveSize={responsiveSize}
      />
    )

    const startDateLabel = queryByTestId('start-date-label')

    expect(startDateLabel).not.toBeInTheDocument()
  })
})
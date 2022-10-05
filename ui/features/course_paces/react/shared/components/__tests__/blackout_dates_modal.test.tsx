/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render} from '@testing-library/react'

import {BLACKOUT_DATES} from '../../../__tests__/fixtures'
import BlackoutDatesModal from '../blackout_dates_modal'

const onCancel = jest.fn()
const onSave = jest.fn()

const defaultProps = {
  open: true,
  blackoutDates: BLACKOUT_DATES,
  onCancel,
  onSave,
}

describe('BlackoutDatesModal', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('opens', () => {
    const {queryByTestId, rerender} = render(<BlackoutDatesModal {...defaultProps} open={false} />)

    expect(queryByTestId('new_blackout_dates_form')).not.toBeInTheDocument()
    expect(queryByTestId('blackout_dates_table')).not.toBeInTheDocument()

    rerender(<BlackoutDatesModal {...defaultProps} />)

    expect(queryByTestId('new_blackout_dates_form')).toBeInTheDocument()
    expect(queryByTestId('blackout_dates_table')).toBeInTheDocument()
  })

  it('handles clicking the "x" close button', () => {
    const {getByRole} = render(<BlackoutDatesModal {...defaultProps} />)

    const closeBtn = getByRole('button', {name: 'Close'})
    act(() => closeBtn.click())

    expect(onCancel).toHaveBeenCalled()
  })

  it('handles clicking the cancel button', () => {
    const {getByRole} = render(<BlackoutDatesModal {...defaultProps} />)

    const cancelBtn = getByRole('button', {name: 'Cancel'})
    act(() => cancelBtn.click())

    expect(onCancel).toHaveBeenCalled()
  })
  it('handles clicking the save button', () => {
    const {getByRole} = render(<BlackoutDatesModal {...defaultProps} />)

    const saveBtn = getByRole('button', {name: 'Save'})
    act(() => saveBtn.click())

    expect(onSave).toHaveBeenCalledWith(defaultProps.blackoutDates)
  })
})

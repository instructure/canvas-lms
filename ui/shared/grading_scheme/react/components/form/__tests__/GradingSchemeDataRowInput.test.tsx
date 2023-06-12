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
import {act, render, screen, fireEvent} from '@testing-library/react'

import {GradingSchemeDataRowInput} from '../GradingSchemeDataRowInput'

const onRowLetterGradeChange = jest.fn()
const onLowRangeChange = jest.fn()
const onRowDeleteRequested = jest.fn()
const onRowAddRequested = jest.fn()
const onLowRangeInputInvalidNumber = jest.fn()

const testProps = {
  dataRow: {name: 'B', value: 0.8},
  highRange: 0.9,
  isFirstRow: false,
  isLastRow: false,
  onRowLetterGradeChange,
  onLowRangeInputInvalidNumber,
  onLowRangeChange,
  onRowDeleteRequested,
  onRowAddRequested,
}

describe('GradingSchemeDataRowInput', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const letterGradeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Letter Grade/,
    })
    expect(letterGradeInput.value).toBe('B')

    const rangeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    expect(rangeInput.value).toBe('80')
  })

  it('onRowLetterGradeChange callback is invoked on changing letter input', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const letterGradeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Letter Grade/,
    })
    fireEvent.change(letterGradeInput, {target: {value: 'X'}})
    expect(onRowLetterGradeChange).toHaveBeenCalledWith('X')
  })

  it('onRowMinScoreChange callback is invoked on changing min score input to valid number', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const rangeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    fireEvent.change(rangeInput, {target: {value: '75'}})
    fireEvent.blur(rangeInput)
    expect(onLowRangeChange).toHaveBeenCalledWith(0.75)
  })

  it('onRowMinScoreChange callback is invoked with rounded value on changing min score input to number with > 2 decimal places', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const rangeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    fireEvent.change(rangeInput, {target: {value: '75.555'}})
    fireEvent.blur(rangeInput)
    expect(onLowRangeChange).toHaveBeenCalledWith(0.7556)
  })

  it('onRowMinScoreChange callback is not invoked on changing min score input to invalid number', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const rangeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    fireEvent.change(rangeInput, {target: {value: '555'}})
    fireEvent.blur(rangeInput)
    expect(onLowRangeChange).not.toHaveBeenCalled()
  })

  it('onRowMinScoreChange callback is not invoked on changing min score input to non numeric value', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const rangeInput = screen.getByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    fireEvent.change(rangeInput, {target: {value: 'foo'}})
    fireEvent.blur(rangeInput)
    expect(onLowRangeChange).not.toHaveBeenCalled()
  })

  it('delete callback is invoked on delete row button press', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const deleteRowButton = screen.getByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    act(() => deleteRowButton.click())
    expect(onRowDeleteRequested).toHaveBeenCalled()
  })

  it('add callback is invoked on add row button press', () => {
    render(
      <table>
        <tbody>
          <GradingSchemeDataRowInput {...testProps} />
        </tbody>
      </table>
    )
    const addRowButton = screen.getByRole<HTMLInputElement>('button', {
      name: /Add new row for a letter grade to grading scheme after this row/,
    })
    act(() => addRowButton.click())
    expect(onRowAddRequested).toHaveBeenCalled()
  })
})

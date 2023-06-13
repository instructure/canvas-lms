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
import {act, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import {
  VALID_FORM_INPUT,
  FORM_INPUT_MISSING_TITLE,
  FORM_INPUT_OVERLAPPING_RANGES,
  SHORT_FORM_INPUT,
} from './fixtures'
import {GradingSchemeInput, GradingSchemeInputHandle} from '../GradingSchemeInput'

const onSave = jest.fn()

describe('GradingSchemeInput', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    render(<GradingSchemeInput initialFormData={VALID_FORM_INPUT} onSave={onSave} />)

    const titleInput = screen.getByRole('textbox', {name: /Grading Scheme Name/})
    expect(titleInput).toBeInTheDocument()

    const letterGradeInputs = screen.getAllByRole<HTMLInputElement>('textbox', {
      name: /Letter Grade/,
    })
    expect(letterGradeInputs.length).toBe(5)
    expect(letterGradeInputs[0].value).toBe('A')
    expect(letterGradeInputs[1].value).toBe('B')
    expect(letterGradeInputs[2].value).toBe('C')
    expect(letterGradeInputs[3].value).toBe('D')
    expect(letterGradeInputs[4].value).toBe('F')

    const rangeInputs = screen.getAllByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    expect(rangeInputs.length).toBe(4)
    expect(rangeInputs[0].value).toBe('90')
    expect(rangeInputs[1].value).toBe('80')
    expect(rangeInputs[2].value).toBe('70')
    expect(rangeInputs[3].value).toBe('60')
    // the last min range is a hard coded 0.0
  })

  it('save callback is invoked on parent imperative save button press when form data is valid', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={VALID_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalled()
  })

  it('data is accurate when all but the first row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={SHORT_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    expect(deleteRowButtons.length).toBe(2)
    act(() => deleteRowButtons[1].click()) // delete the last row
    const newDeleteRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    expect(newDeleteRowButtons.length).toBe(1)
    act(() => gradingSchemeInputRef.current?.savePressed())
    // expect(onSave).toHaveBeenCalled()
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [{name: 'P', value: 0.0}],
    })
  })

  it('data is accurate when all but the last row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={SHORT_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    expect(deleteRowButtons.length).toBe(2)
    act(() => deleteRowButtons[0].click()) // delete the first row
    const newDeleteRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    expect(newDeleteRowButtons.length).toBe(1)
    act(() => gradingSchemeInputRef.current?.savePressed())
    // expect(onSave).toHaveBeenCalled()
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [{name: 'F', value: 0.0}],
    })
  })

  it('data is accurate when the last row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={VALID_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Remove letter grade row/,
    })
    expect(deleteRowButtons.length).toBe(5)
    act(() => deleteRowButtons[4].click()) // delete the last row
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'A', value: 0.9},
        {name: 'B', value: 0.8},
        {name: 'C', value: 0.7},
        {name: 'D', value: 0.0},
      ],
    })
  })

  it('data is accurate when a new row is added', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={SHORT_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const addRowButtons = screen.getAllByRole<HTMLInputElement>('button', {
      name: /Add new row for a letter grade to grading scheme after this row/,
    })
    expect(addRowButtons.length).toBe(2)
    act(() => addRowButtons[0].click()) // add a row after the first row
    const letterGradeInputs = screen.getAllByRole<HTMLInputElement>('textbox', {
      name: /Letter Grade/,
    })
    expect(letterGradeInputs.length).toBe(3) // we've added a row between the initial two
    userEvent.type(letterGradeInputs[1], 'X') // give the new row a letter grade

    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'P', value: 0.5},
        {name: 'X', value: 0.25},
        {name: 'F', value: 0.0},
      ],
    })
  })

  it('validation error displayed when a range is not between 0 and 100', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={SHORT_FORM_INPUT}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByRole<HTMLInputElement>('textbox', {
      name: /Lower limit of range/,
    })
    expect(rangeInputs.length).toBe(1) // note: the 2nd row has a hard coded zero input
    userEvent.type(rangeInputs[0], '-1') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed on parent imperative save button press when title is missing', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={FORM_INPUT_MISSING_TITLE}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed on parent imperative save button press when ranges overlap', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormData={FORM_INPUT_OVERLAPPING_RANGES}
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledTimes(0)
  })
})

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
import userEvent from '@testing-library/user-event'

import {
  VALID_FORM_INPUT,
  FORM_INPUT_MISSING_TITLE,
  FORM_INPUT_OVERLAPPING_RANGES,
  SHORT_FORM_INPUT,
  VALID_FORM_INPUT_POINTS_BASED,
  SHORT_FORM_INPUT_POINTS_BASED,
  FORM_INPUT_DUPLICATE_NAMED_RANGES,
  FORM_INPUT_MISSING_RANGE_NAME,
} from './fixtures'
import {GradingSchemeInput, type GradingSchemeInputHandle} from '../GradingSchemeInput'

const onSave = jest.fn()

describe('GradingSchemeInput', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
      />
    )

    const titleInput = screen.getByLabelText('Grading Scheme Name')
    expect(titleInput).toBeInTheDocument()

    const letterGradeInputs = screen.getAllByLabelText<HTMLInputElement>('Letter Grade')
    expect(letterGradeInputs.length).toBe(5)
    expect(letterGradeInputs[0].value).toBe('A')
    expect(letterGradeInputs[1].value).toBe('B')
    expect(letterGradeInputs[2].value).toBe('C')
    expect(letterGradeInputs[3].value).toBe('D')
    expect(letterGradeInputs[4].value).toBe('F')

    const minRangeCells = screen.getAllByLabelText('Lower limit of range')

    expect((minRangeCells[0] as HTMLInputElement).value).toBe('90')
    expect((minRangeCells[1] as HTMLInputElement).value).toBe('80')
    expect((minRangeCells[2] as HTMLInputElement).value).toBe('70')
    expect((minRangeCells[3] as HTMLInputElement).value).toBe('60')

    expect(minRangeCells[4].textContent).toBe('0%')

    const maxRangeCells = screen.getAllByLabelText('Upper limit of range')

    expect(maxRangeCells.length).toBe(5)
    expect(maxRangeCells[0].textContent).toBe('100%')
    expect(maxRangeCells[1].textContent).toBe('< 90%')
    expect(maxRangeCells[2].textContent).toBe('< 80%')
    expect(maxRangeCells[3].textContent).toBe('< 70%')
    expect(maxRangeCells[4].textContent).toBe('< 60%')
  })

  it('renders points based scheme', () => {
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
      />
    )

    const titleInput = screen.getByLabelText('Grading Scheme Name')
    expect(titleInput).toBeInTheDocument()

    const letterGradeInputs = screen.getAllByLabelText<HTMLInputElement>('Letter Grade')
    expect(letterGradeInputs.length).toBe(4)
    expect(letterGradeInputs[0].value).toBe('A')
    expect(letterGradeInputs[1].value).toBe('B')
    expect(letterGradeInputs[2].value).toBe('C')
    expect(letterGradeInputs[3].value).toBe('D')

    const maxRangeCells = screen.getAllByLabelText('Upper limit of range')
    expect(maxRangeCells.length).toBe(4)
    expect((maxRangeCells[0] as HTMLInputElement).value).toBe('4')
    expect(maxRangeCells[1].textContent).toBe('< 3')
    expect(maxRangeCells[2].textContent).toBe('< 2')
    expect(maxRangeCells[3].textContent).toBe('< 1')

    const minRangeCells = screen.getAllByLabelText('Lower limit of range')

    expect((minRangeCells[0] as HTMLInputElement).value).toBe('3')
    expect((minRangeCells[1] as HTMLInputElement).value).toBe('2')
    expect((minRangeCells[2] as HTMLInputElement).value).toBe('1')
    expect(minRangeCells[3].textContent).toBe('0')
  })

  it('save callback is invoked on parent imperative save button press when form data is valid', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalled()
  })

  it('save callback is invoked on parent imperative save button press when form data is valid points based scheme', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalled()
  })

  it('updates the new first row when the first row is deleted to have the correct max range', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButton = screen.getAllByText('Remove letter grade row')
    act(() => deleteRowButton[0].click())
    const maxRangeCells = screen.getAllByLabelText('Upper limit of range')
    expect(maxRangeCells[0].textContent).toBe('100%')
  })

  it('data is accurate when all but the first row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByText('Remove letter grade row')
    expect(deleteRowButtons.length).toBe(2)
    act(() => deleteRowButtons[1].click()) // delete the last row
    const newDeleteRowButtons = screen.getAllByText('Remove letter grade row')
    expect(newDeleteRowButtons.length).toBe(1)
    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [{name: 'P', value: 0.0}],
      pointsBased: false,
      scalingFactor: 1.0,
    })
  })

  it('data is accurate when all but the last row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByText('Remove letter grade row')
    expect(deleteRowButtons.length).toBe(2)
    act(() => deleteRowButtons[0].click()) // delete the first row
    const newDeleteRowButtons = screen.getAllByText('Remove letter grade row')
    expect(newDeleteRowButtons.length).toBe(1)
    act(() => gradingSchemeInputRef.current?.savePressed())
    // expect(onSave).toHaveBeenCalled()
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [{name: 'F', value: 0.0}],
      pointsBased: false,
      scalingFactor: 1.0,
    })
  })

  it('data is accurate when the last row is deleted', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const deleteRowButtons = screen.getAllByText('Remove letter grade row')
    expect(deleteRowButtons.length).toBe(5)
    act(() => deleteRowButtons[4].click()) // delete the last row
    act(() => gradingSchemeInputRef.current?.savePressed())
    // expect(onSave).toHaveBeenCalled()
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'A', value: 0.9},
        {name: 'B', value: 0.8},
        {name: 'C', value: 0.7},
        {name: 'D', value: 0.0},
      ],
      pointsBased: false,
      scalingFactor: 1.0,
    })
  })

  it('data is accurate when a new row is added', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const addRowButtons = screen.getAllByText(
      'Add new row for a letter grade to grading scheme after this row'
    )

    expect(addRowButtons.length).toBe(2)
    act(() => addRowButtons[0].click()) // add a row after the first row
    const letterGradeInputs = screen.getAllByLabelText('Letter Grade')
    expect(letterGradeInputs.length).toBe(3) // we've added a row between the initial two
    await userEvent.type(letterGradeInputs[1], 'X') // give the new row a letter grade

    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'P', value: 0.5},
        {name: 'X', value: 0.25},
        {name: 'F', value: 0.0},
      ],
      pointsBased: false,
      scalingFactor: 1.0,
    })
  })

  it('data is accurate when a new row is added to points based scheme', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: SHORT_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const addRowButtons = screen.getAllByText(
      'Add new row for a letter grade to grading scheme after this row'
    )
    expect(addRowButtons.length).toBe(2)
    act(() => addRowButtons[0].click()) // add a row after the first row
    const letterGradeInputs = screen.getAllByLabelText<HTMLInputElement>('Letter Grade')
    expect(letterGradeInputs.length).toBe(3) // we've added a row between the initial two
    await userEvent.type(letterGradeInputs[1], 'X') // give the new row a letter grade

    act(() => gradingSchemeInputRef.current?.savePressed())
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'P', value: 0.5},
        {name: 'X', value: 0.25},
        {name: 'F', value: 0.0},
      ],
      pointsBased: true,
      scalingFactor: 4.0,
    })
  })

  it('validation error displayed for points scheme when a max range is not a number', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText('Upper limit of range')

    // note: only the first row allows high range input
    // simulate user input
    await userEvent.clear(rangeInputs[0])
    await userEvent.type(rangeInputs[0], 'foo') // give the 1st highRange an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed for points scheme when upper range is over 100', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText('Upper limit of range')

    // simulate user input
    await userEvent.clear(rangeInputs[0])
    await userEvent.type(rangeInputs[0], '300') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed for points scheme when a lower range is not a number', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )

    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    await userEvent.type(rangeInputs[0], 'foo') // give the 1st row a non numeric value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed for points scheme when a lower range is below 0', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    await userEvent.type(rangeInputs[0], '-1') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed for points scheme when a lower range is above 100', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="points"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    await userEvent.type(rangeInputs[0], '101') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than the upper points range. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when a lower range is not a number', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')

    // simulate user input
    await userEvent.clear(rangeInputs[0])
    await userEvent.type(rangeInputs[0], 'foo') // give the 1st row an invalid value

    // ensure that this value shows in the next row's max range as a string
    const maxRangeCells = screen.getAllByLabelText('Upper limit of range')
    expect(maxRangeCells.length).toBe(5)
    expect(maxRangeCells[0].textContent).toBe('100%')
    expect(maxRangeCells[1].textContent).toBe('< foo%')
    expect(maxRangeCells[2].textContent).toBe('< 80%')
    expect(maxRangeCells[3].textContent).toBe('< 70%')
    expect(maxRangeCells[4].textContent).toBe('< 60%')

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than 100. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when a lower range is below 0', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    await userEvent.type(rangeInputs[0], '-1') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than 100. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when a lower range is above 100', async () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: SHORT_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    await userEvent.type(rangeInputs[0], '101') // give the 1st row an invalid value

    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Range must be a valid number. Cannot have negative numbers or numbers that are greater than 100. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when title is missing', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: FORM_INPUT_MISSING_TITLE,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Grading Scheme Name is required. Add a name and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when ranges overlap', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: FORM_INPUT_OVERLAPPING_RANGES,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when ranges have duplicate names', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: FORM_INPUT_DUPLICATE_NAMED_RANGES,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('validation error displayed when a range has a missing name', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: FORM_INPUT_MISSING_RANGE_NAME,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
        ref={gradingSchemeInputRef}
      />
    )
    act(() => gradingSchemeInputRef.current?.savePressed())
    const validationError = screen.getByText(
      "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
    )
    expect(validationError).toBeInTheDocument()
    expect(onSave).toHaveBeenCalledTimes(0)
  })

  it('when creating scheme, scheme changes to points based upon changing points based radio to true', () => {
    render(
      <GradingSchemeInput
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        schemeInputType="percentage"
        onSave={onSave}
      />
    )

    const titleInput = screen.getByLabelText('Grading Scheme Name')
    expect(titleInput).toBeInTheDocument()

    const percentageRadioInput = screen.getByLabelText<HTMLInputElement>('Percentage')
    expect(percentageRadioInput).toBeChecked()

    const pointsRadioInput = screen.getByLabelText<HTMLInputElement>('Points')
    expect(pointsRadioInput).not.toBeChecked()

    fireEvent.click(pointsRadioInput)
    expect(percentageRadioInput).not.toBeChecked()
    expect(pointsRadioInput).toBeChecked()

    // verify scheme chagned from pct to points defaults
    const letterGradeInputs = screen.getAllByLabelText<HTMLInputElement>('Letter Grade')
    expect(letterGradeInputs.length).toBe(4)
    expect(letterGradeInputs[0].value).toBe('A')
    expect(letterGradeInputs[1].value).toBe('B')
    expect(letterGradeInputs[2].value).toBe('C')
    expect(letterGradeInputs[3].value).toBe('D')

    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    expect(rangeInputs[0].value).toBe('3')
    expect(rangeInputs[1].value).toBe('2')
    expect(rangeInputs[2].value).toBe('1')
    // the last min range is a hard coded 0.0

    // verify upper range on 1st row
    const upperRangeInputs = screen.getAllByLabelText<HTMLInputElement>('Upper limit of range')
    // note: only the first row allows high range input
    expect(upperRangeInputs[0].value).toBe('4')
  })

  it('when editing pct scheme, scheme changes to points based when user toggles radio button', () => {
    const gradingSchemeInputRef = React.createRef<GradingSchemeInputHandle>()

    render(
      <GradingSchemeInput
        ref={gradingSchemeInputRef}
        initialFormDataByInputType={{
          percentage: VALID_FORM_INPUT,
          points: VALID_FORM_INPUT_POINTS_BASED,
        }}
        onSave={onSave}
        schemeInputType="percentage"
      />
    )

    const titleInput = screen.getByLabelText('Grading Scheme Name')
    expect(titleInput).toBeInTheDocument()

    const percentageRadioInput = screen.getByLabelText<HTMLInputElement>('Percentage')
    expect(percentageRadioInput).toBeChecked()

    const pointsRadioInput = screen.getByLabelText<HTMLInputElement>('Points')
    expect(pointsRadioInput).not.toBeChecked()

    fireEvent.click(pointsRadioInput)
    expect(percentageRadioInput).not.toBeChecked()
    expect(pointsRadioInput).toBeChecked()

    // verify scheme changed from pct to points defaults
    const titleInputPoints = screen.getByLabelText<HTMLInputElement>('Grading Scheme Name')
    expect(titleInputPoints).toBeInTheDocument()
    expect(titleInputPoints.value).toEqual('A Grading Scheme') // title does not change when points / pct radio changes

    const letterGradeInputs = screen.getAllByLabelText<HTMLInputElement>('Letter Grade')
    expect(letterGradeInputs.length).toBe(4)
    expect(letterGradeInputs[0].value).toBe('A')
    expect(letterGradeInputs[1].value).toBe('B')
    expect(letterGradeInputs[2].value).toBe('C')
    expect(letterGradeInputs[3].value).toBe('D')

    const rangeInputs = screen.getAllByLabelText<HTMLInputElement>('Lower limit of range')
    expect(rangeInputs[0].value).toBe('3')
    expect(rangeInputs[1].value).toBe('2')
    expect(rangeInputs[2].value).toBe('1')
    // the last min range is a hard coded 0.0

    // verify upper range on 1st row
    const upperRangeInputs = screen.getAllByLabelText<HTMLInputElement>('Upper limit of range')
    // note: only the first row allows high range input
    expect(upperRangeInputs[0].value).toBe('4')

    // save should save the points scheme, not the original pct scheme
    act(() => gradingSchemeInputRef.current?.savePressed())
    // expect(onSave).toHaveBeenCalled()
    expect(onSave).toHaveBeenCalledWith({
      title: 'A Grading Scheme',
      data: [
        {name: 'A', value: 0.75},
        {name: 'B', value: 0.5},
        {name: 'C', value: 0.25},
        {name: 'D', value: 0},
      ],
      pointsBased: true,
      scalingFactor: 4.0,
    })
  })
})

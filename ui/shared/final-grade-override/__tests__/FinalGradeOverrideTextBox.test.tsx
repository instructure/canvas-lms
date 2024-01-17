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
import {FinalGradeOverrideTextBox, type FinalGradeOverrideTextBoxProps} from '../react'
import {fireEvent, render} from '@testing-library/react'
import type {DeprecatedGradingScheme} from '@canvas/grading/grading.d'

const gradingScheme: DeprecatedGradingScheme = {
  data: [
    ['A', 0.94],
    ['A-', 0.9],
    ['B+', 0.87],
    ['B', 0.84],
    ['B-', 0.8],
    ['C+', 0.77],
    ['C', 0.74],
    ['C-', 0.7],
    ['D+', 0.67],
    ['D', 0.64],
    ['D-', 0.61],
    ['F', 0],
  ],
  pointsBased: false,
  scalingFactor: 1,
}

const emptyGradingScheme: DeprecatedGradingScheme = {data: [], pointsBased: false, scalingFactor: 1}

const finalGradeOverrides = {
  courseGrade: {percentage: 84, customGradeStatusId: null},
  gradingPeriodGrades: {'9': {percentage: 43, customGradeStatusId: null}},
}

const mockedOnGradeChange = jest.fn()

const renderTextBox = (props: Partial<FinalGradeOverrideTextBoxProps> = {}) => {
  const defaultProps: FinalGradeOverrideTextBoxProps = {
    gradingScheme,
    finalGradeOverride: finalGradeOverrides,
    onGradeChange: mockedOnGradeChange,
  }
  return render(<FinalGradeOverrideTextBox {...defaultProps} {...props} />)
}

describe('FinalGradeOverrideTextBox', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })
  describe('without a grading scheme', () => {
    it('renders', () => {
      const {getByTestId} = renderTextBox({
        gradingScheme: emptyGradingScheme,
      })
      expect(getByTestId('final-grade-override-textbox')).toBeInTheDocument()
    })

    it('changes the grade when the user inputs a new grade', async () => {
      const {getByTestId} = renderTextBox({
        gradingScheme: emptyGradingScheme,
      })
      const input = getByTestId('final-grade-override-textbox')

      fireEvent.change(input, {target: {value: '93'}})
      fireEvent.blur(input)
      expect(mockedOnGradeChange).toHaveBeenCalled()
      const args = mockedOnGradeChange.mock.calls[0][0]
      expect(args.valid).toBeTruthy()
      expect(args.grade.percentage).toEqual(93)
    })

    it('does not change the grade when the user inputs an invalid grade', async () => {
      const {getByTestId} = renderTextBox({
        gradingScheme: emptyGradingScheme,
      })
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: 'invalid'}})
      fireEvent.blur(input)
      expect(input).toHaveValue('84%')
      expect(mockedOnGradeChange).not.toHaveBeenCalled()
    })

    it('does not change the grade when the user enters the same grade', async () => {
      const {getByTestId} = renderTextBox({
        gradingScheme: emptyGradingScheme,
      })
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: '84'}})
      fireEvent.blur(input)
      expect(mockedOnGradeChange).not.toHaveBeenCalled()
    })
  })
  describe('with a grading scheme', () => {
    it('renders', () => {
      const {getByTestId} = renderTextBox()
      expect(getByTestId('final-grade-override-textbox')).toBeInTheDocument()
    })

    it('replaces the input with the letter grade (replacing trailing en-dash with minus) when the user inputs a valid grade', async () => {
      const {getByTestId} = renderTextBox()
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: '90'}})
      fireEvent.blur(input)
      const args = mockedOnGradeChange.mock.calls[0][0]
      expect(args.valid).toBeTruthy()
      expect(args.grade.percentage).toEqual(90)
      expect(args.grade.schemeKey).toEqual('A−')
    })

    it('does not change the grade when the user enters the same grade', async () => {
      const {getByTestId} = renderTextBox()
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: '84'}})
      fireEvent.blur(input)
      expect(mockedOnGradeChange).not.toHaveBeenCalled()
    })

    it('does not change the grade when the user enters the equivalent letter grade', async () => {
      const {getByTestId} = renderTextBox()
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: 'B'}})
      fireEvent.blur(input)
      expect(mockedOnGradeChange).not.toHaveBeenCalled()
    })

    it('puts the lower bound of the score if entering a letter grade', async () => {
      const {getByTestId} = renderTextBox()
      const input = getByTestId('final-grade-override-textbox')
      fireEvent.change(input, {target: {value: 'C'}})
      fireEvent.blur(input)
      const args = mockedOnGradeChange.mock.calls[0][0]
      expect(args.valid).toBeTruthy()
      expect(args.grade.percentage).toEqual(74)
      expect(args.grade.schemeKey).toEqual('C')
    })
  })
})

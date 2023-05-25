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

import {VALID_FORM_INPUT, FORM_INPUT_MISSING_TITLE, FORM_INPUT_OVERLAPPING_RANGES} from './fixtures'
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

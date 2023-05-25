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
import {act, render, within} from '@testing-library/react'

import {MOCK_DEFAULT_GRADING_SCHEME} from './fixtures'
import {GradingSchemeTemplateView} from '../GradingSchemeTemplateView'

const onDuplicationRequested = jest.fn()

const testProps = {
  gradingSchemeTemplate: MOCK_DEFAULT_GRADING_SCHEME,
  allowDuplicate: true,
  onDuplicationRequested,
}

describe('GradingSchemeTemplateView', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByTestId} = render(<GradingSchemeTemplateView {...testProps} />)
    const x = getByTestId('default_canvas_grading_scheme')
    expect(x).toBeInTheDocument()
    expect(within(x).getByText(MOCK_DEFAULT_GRADING_SCHEME.title)).toBeInTheDocument()

    const dataTable = getByTestId('default_canvas_grading_scheme_data_table')
    expect(dataTable).toBeInTheDocument()
    expect(dataTable.querySelectorAll('tr').length).toBe(6) // 5 data rows plus a table header row

    const row1 = dataTable.querySelectorAll('tr')[1]
    expect(within(row1).getByText('A')).toBeInTheDocument()
    expect(within(row1).getByText('100%')).toBeInTheDocument()
    expect(within(row1).getByText('90%')).toBeInTheDocument()

    const row2 = dataTable.querySelectorAll('tr')[2]
    expect(within(row2).getByText('B')).toBeInTheDocument()
    expect(within(row2).getByText('< 90%')).toBeInTheDocument()
    expect(within(row2).getByText('80%')).toBeInTheDocument()

    const row3 = dataTable.querySelectorAll('tr')[3]
    expect(within(row3).getByText('C')).toBeInTheDocument()
    expect(within(row3).getByText('< 80%')).toBeInTheDocument()
    expect(within(row3).getByText('70%')).toBeInTheDocument()

    const row4 = dataTable.querySelectorAll('tr')[4]
    expect(within(row4).getByText('D')).toBeInTheDocument()
    expect(within(row4).getByText('< 70%')).toBeInTheDocument()
    expect(within(row4).getByText('60%')).toBeInTheDocument()

    const row5 = dataTable.querySelectorAll('tr')[5]
    expect(within(row5).getByText('F')).toBeInTheDocument()
    expect(within(row5).getByText('< 60%')).toBeInTheDocument()
    expect(within(row5).getByText('0%')).toBeInTheDocument()
  })

  it('duplicate callback is invoked on delete button press', () => {
    const {getByTestId} = render(<GradingSchemeTemplateView {...testProps} />)
    const duplicateButton = getByTestId('default_canvas_grading_scheme_duplicate_button')
    act(() => duplicateButton.click())
    expect(onDuplicationRequested).toHaveBeenCalled()
  })
})

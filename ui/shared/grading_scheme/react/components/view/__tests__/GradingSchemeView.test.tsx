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

import {MOCK_COURSE_GRADING_SCHEME} from './fixtures'
import {GradingSchemeView} from '../GradingSchemeView'

const onEditRequested = jest.fn()
const onDeleteRequested = jest.fn()

const testProps = {
  gradingScheme: MOCK_COURSE_GRADING_SCHEME,
  archivedGradingSchemesEnabled: false,
  disableEdit: false,
  disableDelete: false,
  onEditRequested,
  onDeleteRequested,
}

describe('GradingSchemeView', () => {
  afterEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByTestId} = render(<GradingSchemeView {...testProps} />)
    const x = getByTestId(`grading_scheme_${MOCK_COURSE_GRADING_SCHEME.id}`)
    expect(x).toBeInTheDocument()
    expect(within(x).getByText(MOCK_COURSE_GRADING_SCHEME.title)).toBeInTheDocument()

    const dataTable = getByTestId(`grading_scheme_${MOCK_COURSE_GRADING_SCHEME.id}_data_table`)
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

  it('delete callback is invoked on delete button press', () => {
    const {getByTestId} = render(<GradingSchemeView {...testProps} />)
    const delBtn = getByTestId(`grading_scheme_${MOCK_COURSE_GRADING_SCHEME.id}_delete_button`)
    act(() => delBtn.click())
    expect(onDeleteRequested).toHaveBeenCalled()
    // if edit expect(onDeleteRequested.mock.calls[0][0].length).toBe(0) // check params
  })

  it('edit callback is invoked on edit button press', () => {
    const {getByTestId} = render(<GradingSchemeView {...testProps} />)
    const editBtn = getByTestId(`grading_scheme_${MOCK_COURSE_GRADING_SCHEME.id}_edit_button`)
    act(() => editBtn.click())
    expect(onEditRequested).toHaveBeenCalled()
  })
})

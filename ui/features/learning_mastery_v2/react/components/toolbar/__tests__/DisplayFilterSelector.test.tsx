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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DisplayFilter} from '../../../utils/constants'
import {DisplayFilterSelector, DisplayFilterSelectorProps} from '../DisplayFilterSelector'

describe('DisplayFilterSelector', () => {
  const defaultProps: DisplayFilterSelectorProps = {
    values: [],
    onChange: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders checkbox group with correct name and description', () => {
    const {getByText} = render(<DisplayFilterSelector {...defaultProps} />)
    expect(getByText('Display')).toBeInTheDocument()
  })

  it('renders all checkbox options', () => {
    const {getByLabelText} = render(<DisplayFilterSelector {...defaultProps} />)
    expect(getByLabelText('Students with no results')).toBeInTheDocument()
    expect(getByLabelText('Avatars in student list')).toBeInTheDocument()
  })

  it('renders checkboxes with correct values', () => {
    const {getByLabelText} = render(<DisplayFilterSelector {...defaultProps} />)
    const studentsCheckbox = getByLabelText('Students with no results')
    const avatarsCheckbox = getByLabelText('Avatars in student list')

    expect(studentsCheckbox).toHaveAttribute('value', DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS)
    expect(avatarsCheckbox).toHaveAttribute('value', DisplayFilter.SHOW_STUDENT_AVATARS)
  })

  it('displays checkboxes as checked when values are provided', () => {
    const props = {
      ...defaultProps,
      values: [DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS, DisplayFilter.SHOW_STUDENT_AVATARS],
    }
    const {getByLabelText} = render(<DisplayFilterSelector {...props} />)

    expect(getByLabelText('Students with no results')).toBeChecked()
    expect(getByLabelText('Avatars in student list')).toBeChecked()
  })

  it('displays checkboxes as unchecked when values are empty', () => {
    const {getByLabelText} = render(<DisplayFilterSelector {...defaultProps} />)

    expect(getByLabelText('Students with no results')).not.toBeChecked()
    expect(getByLabelText('Avatars in student list')).not.toBeChecked()
  })

  it('calls onChange with updated values when checkbox is clicked', async () => {
    const user = userEvent.setup()
    const onChange = jest.fn()
    const {getByLabelText} = render(<DisplayFilterSelector {...defaultProps} onChange={onChange} />)

    const studentsCheckbox = getByLabelText('Students with no results')
    await user.click(studentsCheckbox)

    expect(onChange).toHaveBeenCalledWith([DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS])
  })

  it('calls onChange with multiple values when multiple checkboxes are selected', async () => {
    const user = userEvent.setup()
    const onChange = jest.fn()
    const {getByLabelText} = render(<DisplayFilterSelector {...defaultProps} onChange={onChange} />)

    const studentsCheckbox = getByLabelText('Students with no results')
    const avatarsCheckbox = getByLabelText('Avatars in student list')

    await user.click(studentsCheckbox)
    await user.click(avatarsCheckbox)

    expect(onChange).toHaveBeenCalledWith([DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS])
    expect(onChange).toHaveBeenCalledWith([
      DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
      DisplayFilter.SHOW_STUDENT_AVATARS,
    ])
  })

  it('calls onChange with empty array when all checkboxes are unchecked', async () => {
    const user = userEvent.setup()
    const onChange = jest.fn()
    const props = {
      ...defaultProps,
      values: [DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS],
      onChange,
    }
    const {getByLabelText} = render(<DisplayFilterSelector {...props} />)

    const studentsCheckbox = getByLabelText('Students with no results')
    await user.click(studentsCheckbox)

    expect(onChange).toHaveBeenCalledWith([])
  })

  it('preserves other selected values when toggling one checkbox', async () => {
    const user = userEvent.setup()
    const onChange = jest.fn()
    const props = {
      ...defaultProps,
      values: [DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS],
      onChange,
    }
    const {getByLabelText} = render(<DisplayFilterSelector {...props} />)

    const avatarsCheckbox = getByLabelText('Avatars in student list')
    await user.click(avatarsCheckbox)

    expect(onChange).toHaveBeenCalledWith([
      DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS,
      DisplayFilter.SHOW_STUDENT_AVATARS,
    ])
  })
})

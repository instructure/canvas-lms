/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import StudentHeader from '../StudentHeader'

describe('StudentHeader', () => {
  let gradebookFilterHandlerMock

  const defaultProps = (props = {}) => ({
    gradebookFilters: [],
    gradebookFilterHandler: gradebookFilterHandlerMock,
  })

  beforeEach(() => {
    gradebookFilterHandlerMock = jest.fn()
  })

  it('renders a "Student" cell', () => {
    const {getByText} = render(<StudentHeader {...defaultProps()} />)
    expect(getByText('Students')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', () => {
    const {getByText} = render(<StudentHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Students'))
    expect(getByText('Sort By')).toBeInTheDocument()
    expect(getByText('Display as')).toBeInTheDocument()
    expect(getByText('Secondary info')).toBeInTheDocument()
    expect(
      getByText('Students without assessments').closest('[role=menuitemcheckbox]')
    ).toBeChecked()
    expect(getByText('Inactive Enrollments').closest('[role=menuitemcheckbox]')).toBeChecked()
    expect(getByText('Concluded Enrollments').closest('[role=menuitemcheckbox]')).toBeChecked()
  })

  describe('gradebook filter handler', () => {
    it("calls gradebook handler function with correct parameter when selecting 'Students without assessments'", () => {
      const {getByText} = render(<StudentHeader {...defaultProps()} />)
      fireEvent.click(getByText('Sort Students'))
      fireEvent.click(getByText('Students without assessments'))
      expect(gradebookFilterHandlerMock).toHaveBeenCalledTimes(1)
      expect(gradebookFilterHandlerMock).toHaveBeenCalledWith('missing_user_rollups')
    })

    it("calls gradebook handler function with correct parameter when selecting 'Inactive Enrollments'", () => {
      const {getByText} = render(<StudentHeader {...defaultProps()} />)
      fireEvent.click(getByText('Sort Students'))
      fireEvent.click(getByText('Inactive Enrollments'))
      expect(gradebookFilterHandlerMock).toHaveBeenCalledTimes(1)
      expect(gradebookFilterHandlerMock).toHaveBeenCalledWith('inactive_enrollments')
    })

    it("calls gradebook handler function with correct parameter when selecting 'Concluded Enrollments'", () => {
      const {getByText} = render(<StudentHeader {...defaultProps()} />)
      fireEvent.click(getByText('Sort Students'))
      fireEvent.click(getByText('Concluded Enrollments'))
      expect(gradebookFilterHandlerMock).toHaveBeenCalledTimes(1)
      expect(gradebookFilterHandlerMock).toHaveBeenCalledWith('concluded_enrollments')
    })
  })
})

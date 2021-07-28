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
  it('renders a "Student" cell', () => {
    const {getByText} = render(<StudentHeader />)
    expect(getByText('Students')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', () => {
    const {getByText} = render(<StudentHeader />)
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
})

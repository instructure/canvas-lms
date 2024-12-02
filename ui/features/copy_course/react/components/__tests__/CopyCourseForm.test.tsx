/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {CopyCourseForm} from '../CopyCourseForm'

describe('CourseCopyForm', () => {
  // CLAB-835
  it.skip('renders the component with all the form fields', () => {
    const {getByText, getByRole} = render(<CopyCourseForm />)

    expect(getByText('Name')).toBeInTheDocument()
    expect(getByText('Course code')).toBeInTheDocument()
    expect(getByText('Start date')).toBeInTheDocument()
    expect(getByText('End date')).toBeInTheDocument()
    expect(getByText('Term')).toBeInTheDocument()
    expect(getByRole('group', {name: 'Content *'})).toBeInTheDocument()
    expect(getByRole('group', {name: 'Options'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Create course'})).toBeInTheDocument()
  })
})

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
 *
 */

import React from 'react'
import {render, waitFor} from '@testing-library/react'

import GradesPage from 'jsx/dashboard/pages/GradesPage'

jest.mock('../utils')
const utils = require('../utils') // eslint-disable-line import/no-commonjs

const defaultCourses = [
  {
    courseId: '1',
    courseName: 'ECON 500',
    isHomeroom: false
  },
  {
    courseId: '2',
    courseName: 'Testing 4 Dummies',
    isHomeroom: false
  },
  {
    courseId: '2',
    courseName: 'Invisible Homeroom',
    isHomeroom: true
  }
]

describe('GradesPage', () => {
  it('displays a loading spinner when grades are loading', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve([]))
    const {getByText} = render(<GradesPage visible />)
    expect(getByText('Loading grades...')).toBeInTheDocument()
  })

  it('displays an error message if there was an error fetching grades', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.reject(new Error('oh no!')))
    const {getAllByText} = render(<GradesPage visible />)
    // showFlashError appears to create both a regular and a screen-reader only alert on the page
    await waitFor(() => getAllByText('Failed to load the grades tab'))
    expect(getAllByText('Failed to load the grades tab')[0]).toBeInTheDocument()
    expect(getAllByText('oh no!')[0]).toBeInTheDocument()
  })

  it('renders fetched non-homeroom courses', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve(defaultCourses))
    const {getByText, queryByText} = render(<GradesPage visible />)
    await waitFor(() => getByText('Testing 4 Dummies'))
    expect(getByText('ECON 500')).toBeInTheDocument()
    expect(queryByText('Invisible Homeroom')).not.toBeInTheDocument()
  })
})

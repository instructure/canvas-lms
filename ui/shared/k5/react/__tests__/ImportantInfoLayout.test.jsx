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
import {render} from '@testing-library/react'
import ImportantInfoLayout from '../ImportantInfoLayout'

describe('ImportantInfoLayout', () => {
  const getProps = (overrides = {}) => ({
    isLoading: false,
    importantInfos: [
      {
        courseId: '10',
        courseName: 'Homeroom 1',
        canEdit: true,
        content: '<p>Hello 1!</p>',
      },
      {
        courseId: '11',
        courseName: 'Homeroom 2',
        canEdit: false,
        content: '<p>Hello 2!</p>',
      },
    ],
    ...overrides,
  })

  afterEach(() => {
    localStorage.clear()
  })

  it('renders each passed important info', () => {
    const {getByText} = render(<ImportantInfoLayout {...getProps()} />)
    expect(getByText('Homeroom 1')).toBeInTheDocument()
    expect(getByText('Homeroom 2')).toBeInTheDocument()
    expect(getByText('Hello 1!')).toBeInTheDocument()
    expect(getByText('Hello 2!')).toBeInTheDocument()
  })

  it('does not render the homeroom title but does show edit button if there is only 1 info to show', () => {
    const importantInfos = [
      {
        courseId: '10',
        courseName: 'Homeroom 1',
        canEdit: true,
        content: '<p>Hello 1!</p>',
      },
    ]
    const {getByText, queryByText, getByRole} = render(
      <ImportantInfoLayout {...getProps({importantInfos})} />
    )
    expect(queryByText('Homeroom 1')).not.toBeInTheDocument()
    expect(getByText('Hello 1!')).toBeInTheDocument()
    const button = getByRole('link', {name: 'Edit important info for Homeroom 1'})
    expect(button).toBeInTheDocument()
    expect(button.href).toContain('/courses/10/assignments/syllabus')
  })

  it('does not render the section title if no infos are passed', () => {
    const {queryByText} = render(<ImportantInfoLayout {...getProps({importantInfos: []})} />)
    expect(queryByText('Important Info')).not.toBeInTheDocument()
  })

  it('renders 1 skeleton if isLoading ', () => {
    const {getByText} = render(<ImportantInfoLayout {...getProps({isLoading: true})} />)
    expect(getByText('Loading important info')).toBeInTheDocument()
  })
})

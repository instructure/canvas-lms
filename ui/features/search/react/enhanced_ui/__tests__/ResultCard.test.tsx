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
import ResultCard from '../ResultCard'

const modules = [
  {
    id: 1,
    name: 'Module 1',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
  {
    id: 2,
    name: 'Module 2',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
  {
    id: 3,
    name: 'Module 3',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
  {
    id: 4,
    name: 'Module 4',
    position: 0,
    prerequisite_module_ids: [],
    published: true,
    items_url: '',
  },
]

const props = {
  courseId: '1',
  searchTerm: 'writing outlines',
  result: {
    content_id: '3',
    content_type: 'Page',
    readable_type: 'page',
    title: 'Course Syllabus',
    body: 'You will submit outlines for your assignments before writing the final paper.',
    html_url: '/courses/1/pages/syllabus',
    distance: 0.9,
    relevance: 0.8,
    modules: modules,
    due_date: null,
    published: true,
  },
}

describe('ResultCard', () => {
  it('should render title and content', () => {
    const {getByText, getByTestId} = render(<ResultCard {...props} />)

    expect(getByText('Course Syllabus')).toBeInTheDocument()
    expect(getByText(/outlines/)).toBeInTheDocument()
    expect(getByText(/writing/)).toBeInTheDocument()
    expect(getByTestId('document_icon')).toBeInTheDocument()
  })

  it('renders modules', () => {
    const {getByText, getAllByTestId} = render(<ResultCard {...props} />)

    expect(getAllByTestId('module_icon')).toHaveLength(4)
    expect(getByText('Module 1')).toBeInTheDocument()
    expect(getByText('Module 2')).toBeInTheDocument()
    expect(getByText('Module 3')).toBeInTheDocument()
    expect(getByText('Module 4')).toBeInTheDocument()
  })

  it('renders only first 5 modules and shows count of extra modules', () => {
    const extraModules = [
      ...modules,
      {
        id: 5,
        name: 'Module 5',
        position: 0,
        prerequisite_module_ids: [],
        published: true,
        items_url: '',
      },
      {
        id: 6,
        name: 'Module 6',
        position: 0,
        prerequisite_module_ids: [],
        published: true,
        items_url: '',
      },
    ]
    const updatedProps = {...props, result: {...props.result, modules: extraModules}}
    const {getByText, getAllByTestId} = render(<ResultCard {...updatedProps} />)

    expect(getAllByTestId('module_icon')).toHaveLength(5)
    expect(getByText('Module 1')).toBeInTheDocument()
    expect(getByText('Module 2')).toBeInTheDocument()
    expect(getByText('Module 3')).toBeInTheDocument()
    expect(getByText('Module 4')).toBeInTheDocument()
    expect(getByText('Module 5')).toBeInTheDocument()
    expect(getByText('1 other module')).toBeInTheDocument()
  })

  it('does not render pills if due_date is null and published is true', () => {
    const {queryByTestId} = render(<ResultCard {...props} />)

    expect(queryByTestId('3-Page-due')).toBeNull()
    expect(queryByTestId('3-Page-publish')).toBeNull()
  })

  it('renders due date and unpublished pills', () => {
    const date = new Date('May 7, 2025 11:00:00').toString()
    const {getByText} = render(
      <ResultCard {...{...props, result: {...props.result, published: false, due_date: date}}} />,
    )

    expect(getByText('Due May 7')).toBeInTheDocument()
    expect(getByText('Unpublished')).toBeInTheDocument()
  })
})

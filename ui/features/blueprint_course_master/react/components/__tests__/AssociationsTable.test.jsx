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
import userEvent from '@testing-library/user-event'
import AssociationsTable from '../AssociationsTable'
import FocusManager from '../../focusManager'
import getSampleData from './getSampleData'

describe('AssociationsTable component', () => {
  const focusManager = new FocusManager()
  focusManager.before = document.body

  const defaultProps = () => ({
    existingAssociations: getSampleData().courses,
    addedAssociations: [],
    removedAssociations: [],
    onRemoveAssociations: () => {},
    onRestoreAssociations: () => {},
    isLoadingAssociations: false,
    focusManager,
  })

  test('renders the AssociationsTable component', () => {
    const {container} = render(<AssociationsTable {...defaultProps()} />)
    const node = container.querySelector('.bca-associations-table')
    expect(node).toBeInTheDocument()
  })

  test('displays correct table data', () => {
    const props = defaultProps()
    const tree = render(<AssociationsTable {...props} />)
    const rows = tree.container.querySelectorAll('tr[data-testid="associations-course-row"]')

    expect(rows).toHaveLength(props.existingAssociations.length)
    expect(rows[0].querySelectorAll('td')[0].textContent).toEqual(
      props.existingAssociations[0].name,
    )
    expect(rows[1].querySelectorAll('td')[0].textContent).toEqual(
      props.existingAssociations[1].name,
    )
  })

  test('calls onRemoveAssociations when association remove button is clicked', async () => {
    const props = defaultProps()
    props.onRemoveAssociations = jest.fn()
    const tree = render(<AssociationsTable {...props} />)
    const button = tree.container.querySelectorAll(
      'tr[data-testid="associations-course-row"] button',
    )
    await userEvent.click(button[0])

    expect(props.onRemoveAssociations).toHaveBeenCalledTimes(1)
    expect(props.onRemoveAssociations).toHaveBeenCalledWith(['1'])
  })

  test('renders concluded pill when course is concluded', () => {
    window.ENV = {FEATURES: {ux_list_concluded_courses_in_bp: true}}

    const props = defaultProps()
    props.existingAssociations = [
      {
        id: '1',
        name: 'Concluded Course',
        course_code: 'CONCLUDED101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
        concluded: true,
      },
    ]

    const {getByText} = render(<AssociationsTable {...props} />)
    const pill = getByText('Concluded')
    expect(pill).toBeInTheDocument()
  })

  test('does not render pill when course is not concluded', () => {
    const props = defaultProps()
    props.existingAssociations = [
      {
        id: '1',
        name: 'Active Course',
        course_code: 'ACTIVE101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
        concluded: false,
      },
    ]

    const {queryByText} = render(<AssociationsTable {...props} />)
    const pill = queryByText('Concluded')
    expect(pill).not.toBeInTheDocument()
  })

  test('renders concluded pill in removedAssociations when course is concluded', () => {
    window.ENV = {FEATURES: {ux_list_concluded_courses_in_bp: true}}

    const props = defaultProps()
    props.existingAssociations = []
    props.removedAssociations = [
      {
        id: '1',
        name: 'Concluded Removed Course',
        course_code: 'CONCLUDED101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher One'}],
        sis_course_id: '1001',
        concluded: true,
      },
    ]

    const {getByText} = render(<AssociationsTable {...props} />)
    const pill = getByText('Concluded')
    expect(pill).toBeInTheDocument()
  })

  test('renders course name as a clickable link with correct href', () => {
    const props = defaultProps()
    const {container} = render(<AssociationsTable {...props} />)
    const firstRow = container.querySelectorAll('tr[data-testid="associations-course-row"]')[0]
    const link = firstRow.querySelector('a[href^="/courses/"]')

    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', `/courses/${props.existingAssociations[0].id}`)
    expect(link).toHaveTextContent(props.existingAssociations[0].name)
  })

  test('renders course links in all association states', () => {
    const props = defaultProps()
    props.addedAssociations = [
      {
        id: '99',
        name: 'Added Course',
        course_code: 'ADDED101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher'}],
        sis_course_id: '9001',
      },
    ]
    props.removedAssociations = [
      {
        id: '88',
        name: 'Removed Course',
        course_code: 'REMOVED101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher'}],
        sis_course_id: '8001',
      },
    ]

    const {container} = render(<AssociationsTable {...props} />)

    // Check for links to existing associations
    props.existingAssociations.forEach(course => {
      const link = container.querySelector(`a[href="/courses/${course.id}"]`)
      expect(link).toBeInTheDocument()
    })

    // Check for link to added association
    const addedLink = container.querySelector(`a[href="/courses/99"]`)
    expect(addedLink).toBeInTheDocument()

    // Check for link to removed association
    const removedLink = container.querySelector(`a[href="/courses/88"]`)
    expect(removedLink).toBeInTheDocument()
  })

  test('falls back to plain text when course ID is missing', () => {
    const props = defaultProps()
    props.existingAssociations = [
      {
        id: null,
        name: 'Course Without ID',
        course_code: 'TEST101',
        term: {id: '1', name: 'Term One'},
        teachers: [{display_name: 'Teacher'}],
        sis_course_id: '1001',
      },
    ]

    const {container} = render(<AssociationsTable {...props} />)
    const firstCell = container.querySelector('tr[data-testid="associations-course-row"] td')
    const link = firstCell.querySelector('a[href^="/courses/"]')

    expect(link).not.toBeInTheDocument()
    expect(firstCell).toHaveTextContent('Course Without ID')
  })
})

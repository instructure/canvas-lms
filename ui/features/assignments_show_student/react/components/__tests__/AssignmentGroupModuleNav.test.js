/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import AssignmentGroupModuleNav from '../AssignmentGroupModuleNav'
import {mockAssignment} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import {render} from '@testing-library/react'

describe('AssignmentGroupModuleNav', () => {
  it('renders module and assignment group links correctly', async () => {
    const assignment = await mockAssignment({
      Assignment: {modules: [{}]},
    })
    const {container, getByTestId} = render(<AssignmentGroupModuleNav assignment={assignment} />)

    const moduleLink = getByTestId('module-link')
    const assignmentGroupLink = getByTestId('assignmentgroup-link')

    expect(moduleLink).toContainElement(container.querySelector('a[href="mocked-module-url"]'))
    expect(assignmentGroupLink).toContainElement(
      container.querySelector('a[href="mocked-assignment-url"]')
    )
  })

  it('renders module and assignment group text correctly', async () => {
    const assignment = await mockAssignment({
      Assignment: {
        modules: [{name: 'Test Module'}],
        assignmentGroup: {name: 'Test assignmentGroup'},
      },
    })
    const {getByTestId, getByText} = render(<AssignmentGroupModuleNav assignment={assignment} />)

    const moduleLink = getByTestId('module-link')
    const assignmentGroupLink = getByTestId('assignmentgroup-link')

    expect(moduleLink).toContainElement(getByText('Test Module'))
    expect(assignmentGroupLink).toContainElement(getByText('Test assignmentGroup'))
  })

  it('will not render module container if not present', async () => {
    const assignment = await mockAssignment({
      Assignment: {
        modules: [],
        assignmentGroup: {name: 'Test assignmentGroup'},
      },
    })
    const {getByTestId, getByText, queryByTestId} = render(
      <AssignmentGroupModuleNav assignment={assignment} />
    )

    const moduleLink = queryByTestId('module-link')
    const assignmentGroupLink = getByTestId('assignmentgroup-link')

    expect(moduleLink).toBeNull()
    expect(assignmentGroupLink).toContainElement(getByText('Test assignmentGroup'))
  })

  it('will not render assignment group container if not present', async () => {
    const assignment = await mockAssignment({
      Assignment: {
        modules: [{name: 'Test Module'}],
        assignmentGroup: null,
      },
    })
    const {getByTestId, getByText, queryByTestId} = render(
      <AssignmentGroupModuleNav assignment={assignment} />
    )

    const moduleLink = getByTestId('module-link')
    const assignmentGroupLink = queryByTestId('assignmentgroup-link')

    expect(moduleLink).toContainElement(getByText('Test Module'))
    expect(assignmentGroupLink).toBeNull()
  })

  it('will render nothing if null props provided', async () => {
    const assignment = await mockAssignment({
      Assignment: {modules: [], assignmentGroup: null},
    })
    const {queryByTestId} = render(<AssignmentGroupModuleNav assignment={assignment} />)

    expect(queryByTestId('module-link')).toBeNull()
    expect(queryByTestId('assignmentgroup-link')).toBeNull()
  })

  it('renders multiple modules', async () => {
    const assignment = await mockAssignment({
      Assignment: {
        modules: [{name: 'Test Module 1'}, {name: 'Test Module 2'}],
      },
    })
    const {getAllByTestId, getByText} = render(<AssignmentGroupModuleNav assignment={assignment} />)

    const modules = getAllByTestId('module-link')
    expect(modules.length).toEqual(2)
    expect(modules[0]).toContainElement(getByText('Test Module 1'))
    expect(modules[1]).toContainElement(getByText('Test Module 2'))
  })

  it('limits the maximum number of modules rendered', async () => {
    const assignment = await mockAssignment({
      Assignment: {
        modules: [{}, {}, {}, {}],
      },
    })
    const {getAllByTestId, getByTestId, getByText} = render(
      <AssignmentGroupModuleNav assignment={assignment} />
    )

    const modules = getAllByTestId('module-link')
    expect(modules.length).toEqual(2)
    const moreModules = getByTestId('more-module-link')
    expect(moreModules).toContainElement(getByText('More Modules'))
  })
})

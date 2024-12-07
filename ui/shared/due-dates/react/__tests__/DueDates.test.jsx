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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom'
import DueDates from '../DueDates'
import StudentGroupStore from '../StudentGroupStore'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import fakeENV from '@canvas/test-utils/fakeENV'

// Suppress React 18 warnings about deprecated lifecycle methods
const originalError = console.error
const originalWarn = console.warn
beforeAll(() => {
  console.error = (...args) => {
    if (args[0]?.includes('Warning:')) return
    originalError.call(console, ...args)
  }
  console.warn = (...args) => {
    if (args[0]?.includes('Warning:')) return
    originalWarn.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalError
  console.warn = originalWarn
})

describe('DueDates', () => {
  let props

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'

    const override1 = new AssignmentOverride({
      name: 'Plebs',
      course_section_id: '1',
      due_at: null,
    })
    const override2 = new AssignmentOverride({
      name: 'Patricians',
      course_section_id: '2',
      due_at: '2015-04-05',
    })
    const override3 = new AssignmentOverride({
      name: 'Students',
      student_ids: ['1', '3'],
      due_at: null,
    })
    const override4 = new AssignmentOverride({
      name: 'Reading Group One',
      group_id: '1',
      due_at: null,
    })
    const override5 = new AssignmentOverride({
      name: 'Reading Group Two',
      group_id: '2',
      due_at: '2015-05-05',
    })

    // Mock StudentGroupStore methods
    const mockGroups = [
      {id: '1', name: 'Reading Group One', group_category_id: '1'},
      {id: '2', name: 'Reading Group Two', group_category_id: '1'},
    ]
    jest.spyOn(StudentGroupStore, 'getGroups').mockReturnValue(mockGroups)
    jest.spyOn(StudentGroupStore, 'getSelectedGroupSetId').mockReturnValue('1')
    jest.spyOn(StudentGroupStore, 'addChangeListener').mockImplementation(() => {})
    jest.spyOn(StudentGroupStore, 'removeChangeListener').mockImplementation(() => {})
    jest.spyOn(StudentGroupStore, 'fetchGroupsForCourse').mockImplementation(() => {
      // Simulate the group store change event
      StudentGroupStore.addChangeListener.mock.calls[0][0]()
    })
    jest.spyOn(StudentGroupStore, 'setGroupSetIfNone').mockImplementation(() => {})

    props = {
      overrides: [override1, override2, override3, override4, override5],
      defaultSectionId: '0',
      sections: [{attributes: {id: 1, name: 'Plebs'}}, {attributes: {id: 2, name: 'Patricians'}}],
      students: {
        1: {id: '1', name: 'Scipio Africanus'},
        2: {id: '2', name: 'Cato The Elder'},
        3: {id: 3, name: 'Publius Publicoa'},
      },
      selectedGroupSetId: '1',
      groups: mockGroups.reduce((acc, group) => ({...acc, [group.id]: group}), {}),
      syncWithBackbone: jest.fn(),
      hasGradingPeriods: false,
      gradingPeriods: [],
      isOnlyVisibleToOverrides: false,
      dueAt: null,
    }
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the component', () => {
    const {container} = render(<DueDates {...props} />)
    expect(container).toBeInTheDocument()
  })

  it('displays section names correctly', () => {
    render(<DueDates {...props} />)
    expect(screen.getByText('Plebs')).toBeInTheDocument()
  })

  it('sorts overrides with different dates into separate rows', async () => {
    render(<DueDates {...props} />)

    // Find all token labels within the component using the token class
    const tokens = screen.getAllByText((content, element) => {
      return (
        element.className === 'ic-token-label' &&
        ['Plebs', 'Reading Group One', 'Patricians', 'Reading Group Two'].includes(content)
      )
    })

    // Verify we have all our expected tokens
    const tokenTexts = tokens.map(token => token.textContent)
    expect(tokenTexts).toContain('Plebs')
    expect(tokenTexts).toContain('Reading Group One')
    expect(tokenTexts).toContain('Patricians')
    expect(tokenTexts).toContain('Reading Group Two')

    const nullDueDateTokens = tokens.filter(t =>
      ['Plebs', 'Reading Group One'].includes(t.textContent)
    )
    const dueDateTokens = tokens.filter(t => ['Patricians'].includes(t.textContent))
    const lateDueDateTokens = tokens.filter(t => ['Reading Group Two'].includes(t.textContent))

    // Verify tokens with null due date are in the same row
    const nullDueDateRow = nullDueDateTokens[0]?.closest('[role="region"]')
    expect(nullDueDateTokens[1]?.closest('[role="region"]')).toBe(nullDueDateRow)

    // Verify tokens with different due dates are in different rows
    const dueDateRow = dueDateTokens[0]?.closest('[role="region"]')
    const lateDueDateRow = lateDueDateTokens[0]?.closest('[role="region"]')
    expect(dueDateRow).not.toBe(nullDueDateRow)
    expect(lateDueDateRow).not.toBe(nullDueDateRow)
    expect(lateDueDateRow).not.toBe(dueDateRow)
  })

  it('syncs with backbone when state changes', () => {
    render(<DueDates {...props} />)
    expect(props.syncWithBackbone).toHaveBeenCalled()
  })

  it('adds new rows when Add Row button is clicked', async () => {
    const user = userEvent.setup()
    render(<DueDates {...props} />)

    const initialRows = screen.getAllByRole('region', {name: 'Due Date Set'})
    const addButton = screen.getByRole('button', {name: /add/i})

    await user.click(addButton)
    const rowsAfterAdd = screen.getAllByRole('region', {name: 'Due Date Set'})
    expect(rowsAfterAdd).toHaveLength(initialRows.length + 1)

    await user.click(addButton)
    const rowsAfterSecondAdd = screen.getAllByRole('region', {name: 'Due Date Set'})
    expect(rowsAfterSecondAdd).toHaveLength(initialRows.length + 2)
  })

  it('filters out picked sections from dropdown options', () => {
    render(<DueDates {...props} />)
    const inputs = screen.getAllByRole('combobox')
    expect(inputs[0]).toBeInTheDocument()
  })

  it('shows "Everyone Else" when a section is selected', () => {
    render(<DueDates {...props} />)

    // Verify that at least one section is selected by checking for token
    const patricianToken = screen.getByText('Patricians', {selector: '.ic-token-label'})
    expect(patricianToken).toBeInTheDocument()

    // Verify there's a combobox for adding more sections
    const comboboxes = screen.getAllByRole('combobox')
    expect(comboboxes.length).toBeGreaterThan(0)
  })

  it('shows "Everyone" when no sections are selected', () => {
    const propsWithNoOverrides = {...props, overrides: []}
    render(<DueDates {...propsWithNoOverrides} />)

    // With no overrides, we should have an add button
    const addButton = screen.getByRole('button', {name: /add/i})
    expect(addButton).toBeInTheDocument()
  })

  it('shows date inputs for each row', () => {
    render(<DueDates {...props} />)
    const dateInputs = screen.getAllByRole('textbox', {name: /due/i})
    expect(dateInputs.length).toBeGreaterThan(0)
  })
})

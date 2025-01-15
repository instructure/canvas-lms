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
import OverrideStudentStore from '../OverrideStudentStore'
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

  it('includes the persisted state on the overrides', () => {
    render(<DueDates {...props} />)
    expect(props.overrides[0].attributes).toHaveProperty('persisted')
  })
})

describe('DueDates with grading periods', () => {
  let props

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    ENV.current_user_roles = ['teacher']

    const overrides = [
      new AssignmentOverride({
        id: '70',
        assignment_id: '64',
        title: 'Section 1',
        due_at: '2014-07-16T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-16',
        unlock_at: null,
        lock_at: null,
        course_section_id: '19',
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true,
      }),
      new AssignmentOverride({
        id: '71',
        assignment_id: '64',
        title: '1 student',
        due_at: '2014-07-17T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-17',
        unlock_at: null,
        lock_at: null,
        student_ids: ['2'],
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true,
      }),
      new AssignmentOverride({
        id: '72',
        assignment_id: '64',
        title: '1 student',
        due_at: '2014-07-18T05:59:59Z',
        all_day: true,
        all_day_date: '2014-07-18',
        unlock_at: null,
        lock_at: null,
        student_ids: ['4'],
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true,
      }),
    ]

    const sections = [
      {attributes: {id: '0', name: 'Everyone'}},
      {
        attributes: {
          id: '19',
          name: 'Section 1',
          start_at: null,
          end_at: null,
          override_course_and_term_dates: null,
        },
      },
      {
        attributes: {
          id: '4',
          name: 'Section 2',
          start_at: null,
          end_at: null,
          override_course_and_term_dates: null,
        },
      },
      {
        attributes: {
          id: '7',
          name: 'Section 3',
          start_at: null,
          end_at: null,
          override_course_and_term_dates: null,
        },
      },
      {
        attributes: {
          id: '8',
          name: 'Section 4',
          start_at: null,
          end_at: null,
          override_course_and_term_dates: null,
        },
      },
    ]

    const gradingPeriods = [
      {
        id: '101',
        title: 'Account Closed Period',
        startDate: new Date('2014-07-01T06:00:00.000Z'),
        endDate: new Date('2014-08-31T06:00:00.000Z'),
        closeDate: new Date('2014-08-31T06:00:00.000Z'),
        isLast: false,
        isClosed: true,
      },
      {
        id: '127',
        title: 'Account Open Period',
        startDate: new Date('2014-09-01T06:00:00.000Z'),
        endDate: new Date('2014-12-15T07:00:00.000Z'),
        closeDate: new Date('2014-12-15T07:00:00.000Z'),
        isLast: true,
        isClosed: false,
      },
    ]

    const students = {
      1: {id: '1', name: 'Scipio Africanus', sections: ['19'], group_ids: []},
      2: {id: '2', name: 'Cato The Elder', sections: ['4'], group_ids: []},
      3: {id: '3', name: 'Publius Publicoa', sections: ['4'], group_ids: []},
      4: {id: '4', name: 'Louie Anderson', sections: ['8'], group_ids: []},
    }

    jest.spyOn(OverrideStudentStore, 'getStudents').mockReturnValue(students)
    jest.spyOn(OverrideStudentStore, 'currentlySearching').mockReturnValue(false)
    jest.spyOn(OverrideStudentStore, 'allStudentsFetched').mockReturnValue(true)

    props = {
      overrides,
      overrideModel: AssignmentOverride,
      defaultSectionId: '0',
      sections,
      groups: {
        1: {id: '1', name: 'Reading Group One'},
        2: {id: '2', name: 'Reading Group Two'},
      },
      syncWithBackbone: jest.fn(),
      hasGradingPeriods: true,
      gradingPeriods,
      isOnlyVisibleToOverrides: true,
      dueAt: null,
    }
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('excludes sections assigned in closed periods from dropdown options', () => {
    render(<DueDates {...props} />)
    const comboboxes = screen.getAllByRole('combobox')
    const options = screen.getAllByRole('option')
    expect(options.map(opt => opt.textContent)).not.toContain('Section 1')
  })

  it('excludes students assigned in closed periods from dropdown options', () => {
    render(<DueDates {...props} />)
    const options = screen.getAllByRole('option')
    expect(options.map(opt => opt.textContent)).not.toContain('Cato The Elder')
  })

  it('includes sections not assigned in closed periods without students assigned in closed periods', () => {
    render(<DueDates {...props} />)
    const options = screen.getAllByRole('option')
    expect(options.map(opt => opt.textContent.trim())).toContain('Section 3')
  })
})

describe('DueDates render callbacks', () => {
  let props

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'

    const override = new AssignmentOverride({
      name: 'Students',
      student_ids: ['1', '3'],
      due_at: null,
    })

    props = {
      overrides: [override],
      defaultSectionId: '0',
      sections: [],
      students: {
        1: {id: '1', name: 'Scipio Africanus'},
        3: {id: 3, name: 'Publius Publicoa'},
      },
      overrideModel: AssignmentOverride,
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

  it('does not fetch adhoc students until state is set', () => {
    const fetchAdhocStudentsStub = jest.spyOn(OverrideStudentStore, 'fetchStudentsByID')
    render(<DueDates {...props} />)
    expect(fetchAdhocStudentsStub).not.toHaveBeenCalledWith(['18', '22'])
    expect(fetchAdhocStudentsStub).toHaveBeenCalledWith(['1', '3'])
  })
})

describe('DueDates important dates', () => {
  let props

  beforeEach(() => {
    fakeENV.setup()
    ENV.K5_SUBJECT_COURSE = true
    ENV.context_asset_string = 'course_1'

    const override1 = new AssignmentOverride({
      name: 'Plebs',
      course_section_id: '1',
      due_at: null,
    })

    props = {
      overrides: [override1],
      defaultSectionId: '0',
      sections: [{attributes: {id: 1, name: 'Plebs'}}],
      students: {
        1: {id: '1', name: 'Scipio Africanus'},
        2: {id: '2', name: 'Cato The Elder'},
        3: {id: 3, name: 'Publius Publicoa'},
      },
      groups: {
        1: {id: '1', name: 'Reading Group One'},
        2: {id: '2', name: 'Reading Group Two'},
      },
      overrideModel: AssignmentOverride,
      syncWithBackbone: jest.fn(),
      hasGradingPeriods: false,
      gradingPeriods: [],
      isOnlyVisibleToOverrides: false,
      dueAt: null,
      importantDates: false,
    }
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('enables important dates checkbox when a date is added', async () => {
    const user = userEvent.setup()
    const {container} = render(<DueDates {...props} />)

    const checkbox = screen.getByRole('checkbox', {name: /mark as important date/i})
    expect(checkbox).toBeDisabled()
    expect(checkbox).not.toBeChecked()

    // Add a date
    const dateInput = container.querySelector('input[type="text"]')
    await user.type(dateInput, '2015-04-05')
    await user.tab()

    expect(checkbox).toBeEnabled()
    expect(checkbox).not.toBeChecked()
  })

  it('is checked if enabled and important dates is true', async () => {
    const user = userEvent.setup()
    props.importantDates = true
    const {container} = render(<DueDates {...props} />)

    const checkbox = screen.getByRole('checkbox', {name: /mark as important date/i})
    expect(checkbox).toBeDisabled()
    expect(checkbox).not.toBeChecked()

    // Add a date
    const dateInput = container.querySelector('input[type="text"]')
    await user.type(dateInput, '2015-04-05')
    await user.tab()

    expect(checkbox).toBeEnabled()
    expect(checkbox).toBeChecked()
  })
})

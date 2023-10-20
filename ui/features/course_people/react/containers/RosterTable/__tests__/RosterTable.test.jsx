/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {render, within, getByText, queryAllByText, screen} from '@testing-library/react'
import React from 'react'
import RosterTable from '../RosterTable'
import {mockUser, getRosterQueryMock} from '../../../../graphql/Mocks'
import {ACTIVE_STATE, PILL_MAP} from '../../../components/StatusPill/StatusPill'
import {OBSERVER_ENROLLMENT, STUDENT_ENROLLMENT} from '../../../../util/constants'
import {
  DESIGNER_1,
  TEACHER_1,
  TA_1,
  STUDENT_1,
  STUDENT_2,
  STUDENT_3,
  OBSERVER_1,
  DATETIME_PATTERN,
  STOPWATCH_PATTERN,
  SITE_ADMIN_ENV,
} from '../../../../util/test-constants'

const mockSettingsToProps = mockSettings => ({
  data: getRosterQueryMock(mockSettings)[0].result.data,
})

const mockUsers = [DESIGNER_1, TEACHER_1, TA_1, STUDENT_1, STUDENT_2, STUDENT_3, OBSERVER_1].map(
  user => mockUser(user)
)

const DEFAULT_PROPS = mockSettingsToProps({mockUsers})

describe('RosterTable', () => {
  const setup = (props = DEFAULT_PROPS) => {
    return render(<RosterTable {...props} />)
  }

  beforeEach(() => {
    window.ENV = SITE_ADMIN_ENV
  })

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('should display a table head with avatar, name, and role column headers at minimum', async () => {
    const container = setup()
    const head = await container.findByTestId('roster-table-head')
    expect(head).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-avatar')).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-name')).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-role')).toBeInTheDocument()
  })

  it('should display a row for each person in the roster', async () => {
    const container = setup()
    expect(await container.findAllByTestId('roster-table-data-row')).toHaveLength(7)
  })

  it('should display data in each table row', async () => {
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    expect(within(rows[0]).getByText(DESIGNER_1.name)).toBeInTheDocument()
    expect(within(rows[0]).getByText(DESIGNER_1.loginId)).toBeInTheDocument()
    expect(within(rows[0]).getByText(DESIGNER_1.sisId)).toBeInTheDocument()
    expect(within(rows[1]).getByText(TEACHER_1.name)).toBeInTheDocument()
    expect(within(rows[1]).getByText(TEACHER_1.loginId)).toBeInTheDocument()
    expect(within(rows[1]).getByText(TEACHER_1.sisId)).toBeInTheDocument()
    expect(within(rows[2]).getByText(TA_1.name)).toBeInTheDocument()
    expect(within(rows[2]).getByText(TA_1.loginId)).toBeInTheDocument()
    expect(within(rows[2]).getByText(TA_1.sisId)).toBeInTheDocument()
    expect(within(rows[2]).getByText('Teaching Assistant')).toBeInTheDocument()
    expect(within(rows[6]).getByText('Observing: Observed Student 1')).toBeInTheDocument()
    expect(within(rows[6]).getByText('Observing: Observed Student 2')).toBeInTheDocument()
  })

  it('should wrap the name of each user in a link to their user detail page', async () => {
    const container = setup()
    const cells = await container.findAllByTestId('roster-table-name-cell')
    const names = mockUsers.map(user => user.name)
    const userDetailLinks = mockUsers.map(user => user.enrollments[0].htmlUrl)
    cells.forEach((cell, index) => {
      const nameMatch = new RegExp(names[index]) // Use regex to match names with pronouns
      const nameLink = within(cell).getByRole('link', {name: nameMatch})
      expect(nameLink).toHaveAttribute('href', userDetailLinks[index])
    })
  })

  it('should display users last activity (if any) unless user is an observer', async () => {
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    const lastActivityByUser = mockUsers.map(user => {
      return user.enrollments[0].type === OBSERVER_ENROLLMENT
        ? null
        : user.enrollments[0].lastActivityAt
    })
    rows.forEach((row, index) => {
      const lastActivity = queryAllByText(row, DATETIME_PATTERN)
      expect(lastActivity).toHaveLength(lastActivityByUser[index] ? 1 : 0)
    })
  })

  it('should display users total activity time only if total time is greater than zero', async () => {
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    const totalActivityByUser = mockUsers.map(user => user.enrollments[0].totalActivityTime)
    rows.forEach((row, index) => {
      const totalActivity = queryAllByText(row, STOPWATCH_PATTERN)
      expect(totalActivity).toHaveLength(totalActivityByUser[index] ? 1 : 0)
    })
  })

  it('should not show the last activity or total activity time column if the read_reports permission is false', async () => {
    window.ENV.permissions.read_reports = false
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')

    // Check there is no column header
    expect(container.queryAllByTestId('colheader-last-activity')).toHaveLength(0)
    expect(container.queryAllByTestId('colheader-total-activity')).toHaveLength(0)

    // Check there is no last activity or total activity time data
    rows.forEach(row => {
      expect(queryAllByText(row, DATETIME_PATTERN)).toHaveLength(0)
      expect(queryAllByText(row, STOPWATCH_PATTERN)).toHaveLength(0)
    })
  })

  it('should list the user pronouns if available', async () => {
    const container = setup()
    const cells = await container.findAllByTestId('roster-table-name-cell')
    const userPronouns = mockUsers.map(user => user.pronouns)
    cells.forEach((cell, index) => {
      if (userPronouns[index]) {
        const pronounMatch = new RegExp(userPronouns[index], 'i')
        expect(within(cell).getByText(pronounMatch)).toBeInTheDocument()
      }
    })
  })

  it('should list the user status if not active', async () => {
    const container = setup()
    const cells = await container.findAllByTestId('roster-table-name-cell')
    const userStatus = mockUsers.map(user => user.enrollments[0].state)
    cells.forEach((cell, index) => {
      if (userStatus[index] !== ACTIVE_STATE) {
        const status = PILL_MAP[userStatus[index]].text
        expect(within(cell).getByText(status)).toBeInTheDocument()
      }
    })
  })

  it('should not show the login ID column if the view_user_logins permission is false', async () => {
    window.ENV.permissions.view_user_logins = false
    const container = setup()

    // Check there is no column header
    const rows = await container.findAllByTestId('roster-table-data-row')
    expect(container.queryAllByTestId('colheader-login-id')).toHaveLength(0)

    // Check there is no login id data
    const loginIdByUser = mockUsers.map(user => user.enrollments[0].loginId)
    rows.forEach((row, index) => {
      loginIdByUser[index] && expect(queryAllByText(row, loginIdByUser[index])).toHaveLength(0)
    })
  })

  it('should not show the SIS ID column if the read_sis permission is false', async () => {
    window.ENV.permissions.read_sis = false
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    const sisIdByUser = mockUsers.map(user => user.enrollments[0].sisId)

    // Check there is no column header
    expect(container.queryAllByTestId('colheader-sis-id')).toHaveLength(0)

    // Check there is no SIS ID data
    rows.forEach((row, index) => {
      sisIdByUser[index] && expect(queryAllByText(row, sisIdByUser[index])).toHaveLength(0)
    })
  })

  it('should show the section column if the hideSectionsOnCourseUsersPage permission is false', async () => {
    window.ENV.course.hideSectionsOnCourseUsersPage = false
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    const sectionByUser = mockUsers.map(user => {
      if (user.enrollments[0].type === OBSERVER_ENROLLMENT) return null
      return user.enrollments[0].section.name
    })

    // Check for column header
    expect(container.getByTestId('colheader-section')).toBeInTheDocument()

    // Check section name exists in row
    rows.forEach((row, index) => {
      sectionByUser[index] && expect(getByText(row, sectionByUser[index])).toBeInTheDocument()
    })
  })

  it('should not show the section column if the hideSectionsOnCourseUsersPage permission is true', async () => {
    window.ENV.course.hideSectionsOnCourseUsersPage = true
    const container = setup()
    const rows = await container.findAllByTestId('roster-table-data-row')
    const sectionByUser = mockUsers.map(user => user.enrollments[0].section.name)

    // Check there is no column header
    expect(container.queryAllByTestId('colheader-section')).toHaveLength(0)

    // Check section name doesn't exist in row
    rows.forEach((row, index) => {
      sectionByUser[index] && expect(queryAllByText(row, sectionByUser[index])).toHaveLength(0)
    })
  })

  describe('Administrative Links', () => {
    const checkContainerForButtons = async (container, users) => {
      await container.findAllByTestId('roster-table-data-row') // Ensure rows are rendered before querying
      const buttonTextList = users.map(user => `Manage ${user.name}`)
      buttonTextList.forEach(async buttonText => {
        expect(await screen.findByRole('button', {name: buttonText})).toBeInTheDocument()
      })
    }

    beforeEach(() => {
      window.ENV.permissions = {
        ...window.ENV.permissions,
        can_allow_admin_actions: false,
        manage_admin_users: false,
        manage_students: false,
      }
    })

    it('should have an Administrative Links column', async () => {
      const container = setup()
      expect(await container.findByTestId('colheader-administrative-links')).toBeInTheDocument()
    })

    it('should show the Administrative Link button if the user can be removed', () => {
      const container = setup() // Mock Users can be removed by default
      checkContainerForButtons(container, mockUsers)
    })

    describe('All enrollments have canBeRemoved=false', () => {
      const mockAdmin = mockUsers.filter(user => user.enrollments[0].type !== STUDENT_ENROLLMENT)
      const mockStudents = mockUsers.filter(user => user.enrollments[0].type === STUDENT_ENROLLMENT)

      beforeAll(() => {
        mockUsers.forEach(user => (user.enrollments[0].canBeRemoved = false))
      })
      afterAll(() => {
        mockUsers.forEach(user => (user.enrollments[0].canBeRemoved = true))
      })

      it('should show the Administrative Link button for students if the user has the manage_students permission', () => {
        window.ENV.permissions.manage_students = true
        const container = setup(mockSettingsToProps({mockUsers: mockStudents}))
        checkContainerForButtons(container, mockStudents)
      })

      it('should show the Administrative Link button for admin roles if the user has the can_allow_admin_actions permission', () => {
        window.ENV.permissions.can_allow_admin_actions = true
        const container = setup(mockSettingsToProps({mockUsers: mockAdmin}))
        checkContainerForButtons(container, mockAdmin)
      })

      it('should show the Administrative Link button for admin roles if the user has the manage_admin_users permission', () => {
        window.ENV.permissions.manage_admin_users = true
        const container = setup(mockSettingsToProps({mockUsers: mockAdmin}))
        checkContainerForButtons(container, mockAdmin)
      })
    })
  })
})

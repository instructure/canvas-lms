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

import {MockedProvider} from '@apollo/react-testing'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {render, within, getByText, queryAllByText} from '@testing-library/react'
import React from 'react'
import RosterTable from '../RosterTable'
import {mockUser, mockEnrollment, getRosterQueryMock} from '../../../../graphql/Mocks'
import {ACTIVE_STATE, PILL_MAP} from '../../../components/StatusPill/StatusPill'

const OBSERVER_ENROLLMENT = 'ObserverEnrollment'
const STUDENT_ENROLLMENT = 'StudentEnrollment'

const designer1 = {
  name: 'Designer 1',
  _id: '10',
  sisId: 'Designer1-SIS-ID',
  loginId: 'Designer1@instructure.com',
  enrollmentType: 'DesignerEnrollment',
  sisRole: 'designer'
}

const teacher1 = {
  name: 'Teacher 1',
  _id: '1',
  avatarUrl: 'https://gravatar.com/avatar/589417b6e62ff03d0aab2179d7b05ab7?s=200&d=identicon&r=pg',
  pronouns: 'He/Him',
  sisId: 'Teacher1-SIS-ID',
  loginId: 'teacher1@instructure.com',
  enrollmentType: 'TeacherEnrollment',
  sisRole: 'teacher',
  lastActivityAt: '2022-07-27T10:21:33-06:00',
  totalActivityTime: 60708
}

const ta1 = {
  name: 'TA 1',
  _id: '22',
  pronouns: 'She/Her',
  sisId: 'TA1-SIS-ID',
  loginId: 'TA1@instructure.com',
  enrollmentType: 'TaEnrollment',
  sisRole: 'ta',
  lastActivityAt: '2022-08-16T14:08:13-06:00',
  totalActivityTime: 407
}

const student1 = {
  name: 'Student 1',
  _id: '31',
  pronouns: 'They/Them',
  sisId: 'Student1-SIS-ID',
  loginId: 'Student1@instructure.com',
  lastActivityAt: '2021-11-04T09:54:01-06:00',
  totalActivityTime: 90
}

const student2 = {
  name: 'Student 2',
  _id: '32',
  avatarUrl: 'https://gravatar.com/avatar/52c160622b09015c70fa0f4c25de6cca?s=200&d=identicon&r=pg',
  sisId: 'Student2-SIS-ID',
  loginId: 'Student2@instructure.com',
  enrollmentStatus: 'invited'
}

const student3 = {
  name: 'Student 3',
  _id: '33',
  sisId: 'Student3-SIS-ID',
  loginId: 'Student3@instructure.com',
  enrollmentStatus: 'inactive'
}

const observer1 = {
  name: 'Observer 1',
  _id: '40',
  sisId: 'Observer1-SIS-ID',
  loginId: 'Observer1@instructure.com',
  enrollmentType: OBSERVER_ENROLLMENT,
  sisRole: 'observer',
  additionalEnrollments: [
    mockEnrollment({
      _id: '40',
      associatedUserID: '123',
      associatedUserName: 'Observed Student 1'
    }),
    mockEnrollment({
      _id: '40',
      associatedUserID: '124',
      associatedUserName: 'Observed Student 2'
    })
  ]
}

const DATETIME_PATTERN = new RegExp(
  /^[a-z]+ [0-3]?[0-9][, [0-9]*]? at [1]?[0-9]:[0-5][0-9](am|pm)$/, // Apr 16, 2021 at 12:34pm
  'i'
)
const STOPWATCH_PATTERN = new RegExp(/^[0-9]+(:[0-5][0-9]){1,2}$/) // 00:00 or 00:00:00

describe('RosterTable', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const mockUsers = [designer1, teacher1, ta1, student1, student2, student3, observer1].map(user =>
    mockUser(user)
  )

  const setup = mocks => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <RosterTable />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  beforeEach(() => {
    window.ENV = {
      course: {
        id: '1',
        hideSectionsOnCourseUsersPage: false
      },
      current_user: {id: '999'},
      permissions: {
        view_user_logins: true,
        read_sis: true,
        read_reports: true,
        can_allow_admin_actions: true,
        manage_admin_users: true,
        manage_students: true
      }
    }
  })

  it('should render', () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    expect(container).toBeTruthy()
  })

  it('should display a table head with avatar, name, and role column headers at minimum', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    const head = await container.findByTestId('roster-table-head')
    expect(head).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-avatar')).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-name')).toBeInTheDocument()
    expect(within(head).getByTestId('colheader-role')).toBeInTheDocument()
  })

  it('should display a row for each person in the roster', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    expect(await container.findAllByTestId('roster-table-data-row')).toHaveLength(7)
  })

  it('should display data in each table row', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    const rows = await container.findAllByTestId('roster-table-data-row')
    expect(within(rows[0]).getByText(designer1.name)).toBeInTheDocument()
    expect(within(rows[0]).getByText(designer1.loginId)).toBeInTheDocument()
    expect(within(rows[0]).getByText(designer1.sisId)).toBeInTheDocument()
    expect(within(rows[1]).getByText(teacher1.name)).toBeInTheDocument()
    expect(within(rows[1]).getByText(teacher1.loginId)).toBeInTheDocument()
    expect(within(rows[1]).getByText(teacher1.sisId)).toBeInTheDocument()
    expect(within(rows[2]).getByText(ta1.name)).toBeInTheDocument()
    expect(within(rows[2]).getByText(ta1.loginId)).toBeInTheDocument()
    expect(within(rows[2]).getByText(ta1.sisId)).toBeInTheDocument()
    expect(within(rows[2]).getByText('Teaching Assistant')).toBeInTheDocument()
    expect(within(rows[6]).getByText('Observing: Observed Student 1')).toBeInTheDocument()
    expect(within(rows[6]).getByText('Observing: Observed Student 2')).toBeInTheDocument()
  })

  it('should wrap the name of each user in a link to their user detail page', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
    const rows = await container.findAllByTestId('roster-table-data-row')
    const totalActivityByUser = mockUsers.map(user => user.enrollments[0].totalActivityTime)
    rows.forEach((row, index) => {
      const totalActivity = queryAllByText(row, STOPWATCH_PATTERN)
      expect(totalActivity).toHaveLength(totalActivityByUser[index] ? 1 : 0)
    })
  })

  it('should not show the last activity or total activity time column if the read_reports permission is false', async () => {
    window.ENV.permissions.read_reports = false
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))

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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const container = setup(getRosterQueryMock({mockUsers}))
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
    const nonRemovableMockUsers = [...mockUsers]
    nonRemovableMockUsers.forEach(user => (user.enrollments[0].canBeRemoved = false))
    const nonRemovableMockAdmin = nonRemovableMockUsers.filter(
      user => user.enrollments[0].type !== STUDENT_ENROLLMENT
    )
    const nonRemovableMockStudents = nonRemovableMockUsers.filter(
      user => user.enrollments[0].type === STUDENT_ENROLLMENT
    )
    const checkContainerForButtons = async (container, users) => {
      const rows = await container.findAllByTestId('roster-table-data-row')
      const buttonNames = users.map(user => `Manage ${user.name}`)
      rows.forEach((row, index) => {
        const button = within(row).getByRole('button', {name: buttonNames[index]})
        expect(button).toBeInTheDocument()
      })
    }

    beforeEach(() => {
      window.ENV.permissions = {
        ...window.ENV.permissions,
        can_allow_admin_actions: false,
        manage_admin_users: false,
        manage_students: false
      }
    })

    it('should have an Administrative Links column', async () => {
      const container = setup(getRosterQueryMock({mockUsers: nonRemovableMockUsers}))
      expect(await container.findByTestId('colheader-administrative-links')).toBeInTheDocument()
    })

    it('should show the Administrative Link button if the user can be removed', () => {
      const container = setup(getRosterQueryMock({mockUsers})) // Mock Users can be removed by default
      checkContainerForButtons(container, mockUsers)
    })

    it('should show the Administrative Link button for students if the user has the manage_students permission', () => {
      window.ENV.permissions.manage_students = true
      const container = setup(getRosterQueryMock({mockUsers: nonRemovableMockStudents}))
      checkContainerForButtons(container, nonRemovableMockStudents)
    })

    it('should show the Administrative Link button for admin roles if the user has the can_allow_admin_actions permission', () => {
      window.ENV.permissions.can_allow_admin_actions = true
      const container = setup(getRosterQueryMock({mockUsers: nonRemovableMockAdmin}))
      checkContainerForButtons(container, nonRemovableMockAdmin)
    })

    it('should show the Administrative Link button for admin roles if the user has the manage_admin_users permission', () => {
      window.ENV.permissions.manage_admin_users = true
      const container = setup(getRosterQueryMock({mockUsers: nonRemovableMockAdmin}))
      checkContainerForButtons(container, nonRemovableMockAdmin)
    })
  })
})

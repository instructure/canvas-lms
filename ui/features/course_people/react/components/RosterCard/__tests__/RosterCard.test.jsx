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

import {render, within, queryAllByText} from '@testing-library/react'
import React from 'react'
import RosterCard from '../RosterCard'
import {mockUser, getRosterQueryMock} from '../../../../graphql/Mocks'
import {PILL_MAP, INACTIVE_STATE, PENDING_STATE} from '../../StatusPill/StatusPill'
import {getRoleName} from '../../RosterTableRoles/RosterTableRoles'
import {
  TEACHER_1,
  STUDENT_1,
  STUDENT_2,
  STUDENT_3,
  OBSERVER_1,
  DATETIME_PATTERN,
  STOPWATCH_PATTERN,
  SITE_ADMIN_ENV,
} from '../../../../util/test-constants'

const userToProps = user => ({
  courseUsersConnectionNode: getRosterQueryMock({mockUsers: [mockUser(user)]})[0].result.data.course
    .usersConnection.nodes[0],
})

const mockSettingsToProps = mockSettings => ({
  courseUsersConnectionNode:
    getRosterQueryMock(mockSettings)[0].result.data.course.usersConnection.nodes[0],
})

const DEFAULT_PROPS = userToProps(STUDENT_1)

describe('RosterCard', () => {
  const setup = (props = DEFAULT_PROPS) => {
    return render(<RosterCard {...props} />)
  }

  beforeEach(() => {
    window.ENV = SITE_ADMIN_ENV
  })

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('should display a card with an avatar, name, and enrollment table', () => {
    const {name, enrollments} = DEFAULT_PROPS.courseUsersConnectionNode
    const nameMatch = new RegExp(name) // Use regex to match names with pronouns
    const {getByRole, getAllByRole, getByTestId} = setup()

    const links = getAllByRole('link', {name: nameMatch})
    expect(links).toHaveLength(2) // Avatar and Name
    links.forEach(link => expect(link).toHaveAttribute('href', enrollments[0].htmlUrl))
    expect(getByRole('img', {name: nameMatch})).toBeInTheDocument()
    expect(getByRole('table', {name: 'Enrollment Details'})).toBeInTheDocument()
    expect(getByTestId('enrollment-table-head')).toBeInTheDocument()
    expect(getByTestId('colheader-section')).toBeInTheDocument()
    expect(getByTestId('colheader-role')).toBeInTheDocument()
    expect(getByTestId('colheader-last-activity')).toBeInTheDocument()
    expect(getByTestId('colheader-total-activity')).toBeInTheDocument()
  })

  it('should display a table row with data for each enrollment', async () => {
    const {enrollments} = DEFAULT_PROPS.courseUsersConnectionNode
    const {findAllByTestId} = setup()

    const rows = await findAllByTestId('enrollment-table-data-row')
    expect(rows).toHaveLength(enrollments.length)
    rows.forEach((row, index) => {
      expect(within(row).getByText(enrollments[index].section.name)).toBeInTheDocument() // Section Name
      expect(within(row).getByText(getRoleName(enrollments[index]))).toBeInTheDocument() // Role
      expect(within(row).getByText(DATETIME_PATTERN)).toBeInTheDocument() // Last Activity
      expect(within(row).getByText(STOPWATCH_PATTERN)).toBeInTheDocument() // Total Activity
    })
  })

  it('should not display last activity if user is an observer', async () => {
    const container = setup(userToProps(OBSERVER_1))
    const rows = await container.findAllByTestId('enrollment-table-data-row')
    rows.forEach(row => {
      expect(queryAllByText(row, DATETIME_PATTERN)).toHaveLength(0)
    })
  })

  it('should not display total activity time if it is equal to zero', async () => {
    const container = setup(userToProps(STUDENT_2))
    const row = await container.findByTestId('enrollment-table-data-row')
    expect(within(row).queryByText(STOPWATCH_PATTERN)).not.toBeInTheDocument()
  })

  it('should not show the last activity or total activity time column if the read_reports permission is false', async () => {
    window.ENV.permissions.read_reports = false
    const container = setup()
    const rows = await container.findAllByTestId('enrollment-table-data-row')

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
    const {pronouns} = DEFAULT_PROPS.courseUsersConnectionNode
    const container = setup()
    const pronounMatch = new RegExp(pronouns, 'i')
    expect(container.getByText(pronounMatch)).toBeInTheDocument()
  })

  it('should list the user status if pending', async () => {
    const {getByText} = setup(userToProps(STUDENT_2))
    const pillText = PILL_MAP[PENDING_STATE].text
    expect(getByText(pillText)).toBeInTheDocument()
  })

  it('should list the user status if inactive', async () => {
    const {getByText} = setup(userToProps(STUDENT_3))
    const pillText = PILL_MAP[INACTIVE_STATE].text
    expect(getByText(pillText)).toBeInTheDocument()
  })

  it('should display the login ID of the user in the card', () => {
    const {loginId} = DEFAULT_PROPS.courseUsersConnectionNode
    const loginIdPrefixPattern = new RegExp('Login ID', 'i')
    const loginIdPattern = new RegExp(loginId)
    const container = setup()
    expect(container.getByText(loginIdPrefixPattern)).toBeInTheDocument()
    expect(container.getByText(loginIdPattern)).toBeInTheDocument()
  })

  it('should not show the login ID of the user if the view_user_logins permission is false', () => {
    window.ENV.permissions.view_user_logins = false
    const {loginId} = DEFAULT_PROPS.courseUsersConnectionNode
    const loginIdPrefixPattern = new RegExp('Login ID', 'i')
    const loginIdPattern = new RegExp(loginId)
    const container = setup()
    expect(container.queryAllByText(loginIdPrefixPattern)).toHaveLength(0)
    expect(container.queryAllByText(loginIdPattern)).toHaveLength(0)
  })

  it('should show the SIS ID of the user in the card', async () => {
    const {sisId} = DEFAULT_PROPS.courseUsersConnectionNode
    const sisIdPrefixPattern = new RegExp('SIS ID', 'i')
    const sisIdPattern = new RegExp(sisId)
    const container = setup()
    expect(container.getByText(sisIdPrefixPattern)).toBeInTheDocument()
    expect(container.getByText(sisIdPattern)).toBeInTheDocument()
  })

  it('should not show the SIS ID of the user if the read_sis permission is false', async () => {
    window.ENV.permissions.read_sis = false
    const {sisId} = DEFAULT_PROPS.courseUsersConnectionNode
    const sisIdPrefixPattern = new RegExp('SIS ID', 'i')
    const sisIdPattern = new RegExp(sisId)
    const container = setup()
    expect(container.queryAllByText(sisIdPrefixPattern)).toHaveLength(0)
    expect(container.queryAllByText(sisIdPattern)).toHaveLength(0)
  })

  it('should not show the enrollment section column if the hideSectionsOnCourseUsersPage permission is true', async () => {
    window.ENV.course.hideSectionsOnCourseUsersPage = true
    const {enrollments} = DEFAULT_PROPS.courseUsersConnectionNode
    const sections = enrollments.map(enrollment => enrollment.section.name)
    const container = setup()
    const rows = await container.findAllByTestId('enrollment-table-data-row')

    expect(container.queryAllByTestId('colheader-section')).toHaveLength(0)
    rows.forEach((row, index) => {
      expect(queryAllByText(row, sections[index])).toHaveLength(0)
    })
  })

  describe('Administrative Links', () => {
    const checkContainerForButtons = async (container, name) => {
      await container.findAllByTestId('enrollment-table-data-row') // Ensure rows are rendered before querying
      expect(await container.findByRole('button', {name: `Manage ${name}`})).toBeInTheDocument()
    }

    beforeEach(() => {
      window.ENV.permissions = {
        ...window.ENV.permissions,
        can_allow_admin_actions: false,
        manage_admin_users: false,
        manage_students: false,
      }
    })

    it('should show the Administrative Link button if the user can be removed', () => {
      const {name} = DEFAULT_PROPS.courseUsersConnectionNode
      const container = setup() // Students can be removed by default
      checkContainerForButtons(container, name)
    })

    describe('All enrollments have canBeRemoved=false', () => {
      const mockStudent = mockUser(STUDENT_1)
      const mockTeacher = mockUser(TEACHER_1)
      mockStudent.enrollments[0].canBeRemoved = false
      mockTeacher.enrollments[0].canBeRemoved = false

      it('should show the Administrative Link button for students if the user has the manage_students permission', () => {
        window.ENV.permissions.manage_students = true
        const container = setup(mockSettingsToProps({mockUsers: [mockStudent]}))
        checkContainerForButtons(container, mockStudent.name)
      })

      it('should show the Administrative Link button for admin roles if the user has the can_allow_admin_actions permission', () => {
        window.ENV.permissions.can_allow_admin_actions = true
        const container = setup(mockSettingsToProps({mockUsers: [mockTeacher]}))
        checkContainerForButtons(container, mockTeacher.name)
      })

      it('should show the Administrative Link button for admin roles if the user has the manage_admin_users permission', () => {
        window.ENV.permissions.manage_admin_users = true
        const container = setup(mockSettingsToProps({mockUsers: [mockTeacher]}))
        checkContainerForButtons(container, mockTeacher.name)
      })
    })
  })
})

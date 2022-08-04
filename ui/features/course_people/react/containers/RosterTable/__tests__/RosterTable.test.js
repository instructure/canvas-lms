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
import {render, within} from '@testing-library/react'
import React from 'react'
import RosterTable from '../RosterTable'
import {mockUser, mockEnrollment, getRosterQueryMock} from '../../../../graphql/Mocks'

const designer1 = {
  name: 'Designer 1',
  _id: '10',
  sisId: 'Designer1-SIS-ID',
  loginId: 'Designer1@instructure.com',
  enrollmentType: 'DesignerEnrollment'
}

const teacher1 = {
  name: 'Teacher 1',
  _id: '1',
  avatarUrl: 'https://gravatar.com/avatar/589417b6e62ff03d0aab2179d7b05ab7?s=200&d=identicon&r=pg',
  pronouns: 'He/Him',
  sisId: 'Teacher1-SIS-ID',
  loginId: 'teacher1@instructure.com',
  enrollmentType: 'TeacherEnrollment',
  lastActivityAt: '2022-07-27T10:11:33-06:00',
  totalActivityTime: 60708
}

const ta1 = {
  name: 'TA 1',
  _id: '22',
  pronouns: 'She/Her',
  sisId: 'TA1-SIS-ID',
  loginId: 'TA1@instructure.com',
  enrollmentType: 'TaEnrollment'
}

const student1 = {
  name: 'Student 1',
  _id: '31',
  pronouns: 'They/Them',
  sisId: 'Student1-SIS-ID',
  loginId: 'Student1@instructure.com'
}

const student2 = {
  name: 'Student 2',
  _id: '32',
  avatarUrl: 'https://gravatar.com/avatar/52c160622b09015c70fa0f4c25de6cca?s=200&d=identicon&r=pg',
  sisId: 'Student2-SIS-ID',
  loginId: 'Student2@instructure.com',
  enrollmentStatus: 'pending'
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
  enrollmentType: 'ObserverEnrollment',
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
      course: {id: '1'},
      current_user: {id: '999'}
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

  it('should wrap the name of each user in a button', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    const rows = await container.findAllByTestId('roster-table-data-row')
    const names = [designer1, teacher1, ta1, student1, student2, student3, observer1].map(
      user => user.name
    )
    rows.forEach((row, index) => {
      const button = within(row).getByRole('button', {name: names[index]})
      expect(button).toBeInTheDocument()
    })
  })

  it('should link the current_user to their user detail page when clicking their own name', async () => {
    window.ENV = {...window.ENV, current_user: {id: '1'}}
    const container = setup(getRosterQueryMock({mockUsers}))
    const link = await container.findByRole('link', {name: teacher1.name})
    expect(link).toHaveAttribute('href', mockUsers[1].node.enrollments.htmlUrl)
  })

  it('should not link the current_user to the user detail page when clicking a name that is not their own', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    const rows = await container.findAllByTestId('roster-table-data-row')
    const names = [designer1, teacher1, ta1, student1, student2, student3, observer1].map(
      user => user.name
    )
    rows.forEach((row, index) => {
      const button = within(row).getByRole('button', {name: names[index]})
      expect(button).not.toHaveAttribute('href')
    })
  })
})

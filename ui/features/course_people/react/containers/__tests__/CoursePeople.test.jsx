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
import CoursePeople from '../CoursePeople'
import {getRosterQueryMock, mockUser} from '../../../graphql/Mocks'
import {responsiveQuerySizes} from '../../../util/utils'
import {getRoleName} from '../../components/RosterTableRoles/RosterTableRoles'
import {OBSERVER_ENROLLMENT} from '../../../util/constants'
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
} from '../../../util/test-constants'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('CoursePeople', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const mockUsers = [DESIGNER_1, TEACHER_1, TA_1, STUDENT_1, STUDENT_2, STUDENT_3, OBSERVER_1].map(
    user => mockUser(user)
  )

  const setup = mocks => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <CoursePeople />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  beforeEach(() => {
    window.ENV = SITE_ADMIN_ENV
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })

    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '1024px'},
    }))
  })

  it('should render', () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    expect(container).toBeTruthy()
  })

  it('should render a roster table with user data on desktop size screens', async () => {
    const container = setup(getRosterQueryMock({mockUsers}))
    expect(await container.findByRole('table')).toBeInTheDocument()
    const rows = container.getAllByTestId('roster-table-data-row')
    expect(rows).toHaveLength(mockUsers.length)

    rows.forEach((row, index) => {
      const {name, sisId, loginId, enrollments} = mockUsers[index]
      const {type, section, lastActivityAt, totalActivityTime} = enrollments[0]
      const textToCheck = [name, sisId, loginId]
      if (type !== OBSERVER_ENROLLMENT) {
        textToCheck.push(section.name, getRoleName(enrollments[0]))
        lastActivityAt && textToCheck.push(DATETIME_PATTERN)
      }
      totalActivityTime && textToCheck.push(STOPWATCH_PATTERN)

      textToCheck.forEach(text =>
        expect(within(row).getAllByText(text).length).toBeGreaterThanOrEqual(1)
      )
    })
  })

  it('should render cards with user data on tablet size screens and smaller', async () => {
    responsiveQuerySizes.mockImplementation(() => ({
      tablet: {maxWidth: '100px'},
    }))
    const container = setup(getRosterQueryMock({mockUsers}))
    expect(await container.findByRole('list')).toBeInTheDocument()
    const list = container.getAllByRole('listitem')
    expect(list).toHaveLength(mockUsers.length)

    list.forEach((listItem, index) => {
      const {name, sisId, loginId, enrollments} = mockUsers[index]
      const {type, section, lastActivityAt, totalActivityTime} = enrollments[0]
      const textToCheck = [name, sisId, loginId]
      if (type !== OBSERVER_ENROLLMENT) {
        textToCheck.push(section.name, getRoleName(enrollments[0]))
        lastActivityAt && textToCheck.push(DATETIME_PATTERN)
      }
      totalActivityTime && textToCheck.push(STOPWATCH_PATTERN)

      textToCheck.forEach(text =>
        expect(within(listItem).getAllByText(text).length).toBeGreaterThanOrEqual(1)
      )
    })
  })
})

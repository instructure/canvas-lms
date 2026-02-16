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

import {MockedProvider} from '@apollo/client/testing'
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

vi.mock('../../../util/utils', async () => ({
  ...(await vi.importActual('../../../util/utils')),
  responsiveQuerySizes: vi.fn(),
}))

describe('CoursePeople', () => {
  const setOnFailure = vi.fn()
  const setOnSuccess = vi.fn()
  const mockUsers = [DESIGNER_1, TEACHER_1, TA_1, STUDENT_1, STUDENT_2, STUDENT_3, OBSERVER_1].map(
    (user: any) => mockUser(user),
  )

  const setup = (mocks: ReturnType<typeof getRosterQueryMock>) => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <CoursePeople />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
  }

  beforeEach(() => {
    window.ENV = {
      ...SITE_ADMIN_ENV,
      course: {
        id: SITE_ADMIN_ENV.course.id,
        name: 'Test Course',
        start_at: '2021-01-01T00:00:00Z',
        end_at: '2021-12-31T23:59:59Z',
        created_at: '2021-01-01T00:00:00Z',
        // @ts-expect-error hideSectionsOnCourseUsersPage is not in Course type yet
        hideSectionsOnCourseUsersPage: SITE_ADMIN_ENV.course.hideSectionsOnCourseUsersPage,
      },
    }
    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })

    ;(responsiveQuerySizes as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      desktop: {minWidth: '1024px'},
    }))
  })

  it('should render', () => {
    const container = setup(getRosterQueryMock({mockUsers: mockUsers as any}))
    expect(container).toBeTruthy()
  })

  it('should render a roster table with user data on desktop size screens', async () => {
    const container = setup(getRosterQueryMock({mockUsers: mockUsers as any}))
    expect(await container.findByRole('table')).toBeInTheDocument()
    const rows = container.getAllByTestId('roster-table-data-row')
    expect(rows).toHaveLength(mockUsers.length)

    rows.forEach((row, index) => {
      const {name, sisId, loginId, enrollments} = mockUsers[index]
      const {type, section, lastActivityAt, totalActivityTime} = enrollments[0]
      const textToCheck: Array<string | RegExp | null> = [name, sisId, loginId]
      if (type !== OBSERVER_ENROLLMENT) {
        textToCheck.push(section.name, getRoleName(enrollments[0]))
        lastActivityAt && textToCheck.push(DATETIME_PATTERN)
      }
      totalActivityTime && textToCheck.push(STOPWATCH_PATTERN)

      textToCheck.forEach((text: string | RegExp | null) => {
        if (text !== null) {
          const matches = within(row).queryAllByText(text)
          expect(matches.length).toBeGreaterThanOrEqual(1)
        }
      })
    })
  })

  it('should render cards with user data on tablet size screens and smaller', async () => {
    ;(responsiveQuerySizes as ReturnType<typeof vi.fn>).mockImplementation(() => ({
      tablet: {maxWidth: '100px'},
    }))
    const container = setup(getRosterQueryMock({mockUsers: mockUsers as any}))
    expect(await container.findByRole('list')).toBeInTheDocument()
    const list = container.getAllByRole('listitem')
    expect(list).toHaveLength(mockUsers.length)

    list.forEach((listItem, index) => {
      const {name, sisId, loginId, enrollments} = mockUsers[index]
      const {type, section, lastActivityAt, totalActivityTime} = enrollments[0]
      const textToCheck: Array<string | RegExp | null> = [name, sisId, loginId]
      if (type !== OBSERVER_ENROLLMENT) {
        textToCheck.push(section.name, getRoleName(enrollments[0]))
        lastActivityAt && textToCheck.push(DATETIME_PATTERN)
      }
      totalActivityTime && textToCheck.push(STOPWATCH_PATTERN)

      textToCheck.forEach((text: string | RegExp | null) => {
        if (text !== null) {
          const matches = within(listItem).queryAllByText(text)
          expect(matches.length).toBeGreaterThanOrEqual(1)
        }
      })
    })
  })
})

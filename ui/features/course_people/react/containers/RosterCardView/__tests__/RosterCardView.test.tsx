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

import {render, within} from '@testing-library/react'
import React from 'react'
import RosterCardView from '../RosterCardView'
import {mockUser, getRosterQueryMock} from '../../../../graphql/Mocks'
import {getRoleName} from '../../../components/RosterTableRoles/RosterTableRoles'
import {OBSERVER_ENROLLMENT} from '../../../../util/constants'
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

const mockSettingsToProps = (mockSettings: Parameters<typeof getRosterQueryMock>[0]) => ({
  data: getRosterQueryMock(mockSettings)[0].result.data,
})

const mockUsers = [DESIGNER_1, TEACHER_1, TA_1, STUDENT_1, STUDENT_2, STUDENT_3, OBSERVER_1].map(
  (user: any) => mockUser(user),
)

const DEFAULT_PROPS = mockSettingsToProps({mockUsers: mockUsers as any})

describe('RosterCardView', () => {
  const setup = (props = DEFAULT_PROPS) => {
    return render(<RosterCardView {...props} />)
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
  })

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('should render a list of cards with user data', () => {
    const container = setup()
    expect(container.getByRole('list')).toBeInTheDocument()
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

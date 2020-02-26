/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import AlertManager from '../../../shared/components/AlertManager'
import CourseNotificationSettings from '../CourseNotificationSettings'
import {fireEvent, render} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import mockGraphqlQuery from '../../../shared/graphql_query_mock'
import React from 'react'
import {UPDATE_COURSE_NOTIFICATION_PREFERENCES} from '../graphqlData/Mutations'

async function createGraphqlMocks() {
  const enabledResult = await mockGraphqlQuery(UPDATE_COURSE_NOTIFICATION_PREFERENCES, [], {
    courseId: 1,
    enabled: true
  })
  const disabledResult = await mockGraphqlQuery(UPDATE_COURSE_NOTIFICATION_PREFERENCES, [], {
    courseId: 1,
    enabled: false
  })
  return [
    {
      request: {
        query: UPDATE_COURSE_NOTIFICATION_PREFERENCES,
        variables: {
          courseId: '1',
          enabled: true
        }
      },
      result: enabledResult
    },
    {
      request: {
        query: UPDATE_COURSE_NOTIFICATION_PREFERENCES,
        variables: {
          courseId: '1',
          enabled: false
        }
      },
      result: disabledResult
    }
  ]
}

describe('Course Notification Settings', () => {
  it('updates correctly', async () => {
    const mocks = await createGraphqlMocks()
    const {findByText, findByTestId} = render(
      <MockedProvider mocks={mocks}>
        <AlertManager>
          <CourseNotificationSettings enabled courseId="1" />
        </AlertManager>
      </MockedProvider>
    )

    expect(await findByTestId('enable-notifications-toggle')).toBeInTheDocument()
    expect(
      await findByText(
        'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()

    fireEvent.click(await findByTestId('enable-notifications-toggle'))
    expect(
      await findByText(
        'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })
})

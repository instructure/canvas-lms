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
import CourseNotificationSettingsQuery from '../CourseNotificationSettingsQuery'
import {COURSE_NOTIFICATIONS_ENABLED_QUERY} from '../graphqlData/Queries'
import {createCache} from 'jsx/canvas-apollo'
import {render} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import mockGraphqlQuery from '../../../shared/graphql_query_mock'
import React from 'react'

async function createGraphqlMocks(queryOverrides) {
  if (!Array.isArray(queryOverrides)) {
    queryOverrides = [queryOverrides]
  }
  const queryResult = await mockGraphqlQuery(COURSE_NOTIFICATIONS_ENABLED_QUERY, queryOverrides, {
    courseId: 1
  })

  return [
    {
      request: {
        query: COURSE_NOTIFICATIONS_ENABLED_QUERY,
        variables: {
          courseId: '1'
        }
      },
      result: queryResult
    }
  ]
}

describe('Course Notification Settings', () => {
  it('displays the correct messaging for enabled notification settings', async () => {
    const mocks = await createGraphqlMocks({
      Course: {
        _id: 1,
        notificationPreferencesEnabled: true
      }
    })
    const {findByText, findByTestId} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AlertManager>
          <CourseNotificationSettingsQuery courseId="1" />
        </AlertManager>
      </MockedProvider>
    )

    expect(await findByTestId('enable-notifications-toggle')).toBeInTheDocument()
    expect(
      await findByText(
        'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })

  it('displays the correct messaging for disabled notification settings', async () => {
    const mocks = await createGraphqlMocks({
      Course: {
        _id: 1,
        notificationPreferencesEnabled: false
      }
    })
    const {findByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AlertManager>
          <CourseNotificationSettingsQuery courseId="1" />
        </AlertManager>
      </MockedProvider>
    )

    expect(
      await findByText(
        'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })
})

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
import AlertManager, {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import CourseNotificationSettingsQuery from '../CourseNotificationSettingsQuery'
import CourseNotificationSettingsManager from '../CourseNotificationSettingsManager'
import {COURSE_NOTIFICATIONS_QUERY} from '../../graphql/Queries'
import {UPDATE_COURSE_NOTIFICATION_PREFERENCES} from '../../graphql/Mutations'
import {createCache} from '@canvas/apollo'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import mockGraphqlQuery from '@canvas/graphql-query-mock'
import React from 'react'

async function createQueryMocks(queryOverrides) {
  if (!Array.isArray(queryOverrides)) {
    queryOverrides = [queryOverrides]
  }
  const queryResult = await mockGraphqlQuery(COURSE_NOTIFICATIONS_QUERY, queryOverrides, {
    courseId: 1,
    userId: 1,
  })

  return [
    {
      request: {
        query: COURSE_NOTIFICATIONS_QUERY,
        variables: {
          courseId: '1',
          userId: '1',
        },
      },
      result: queryResult,
    },
  ]
}

async function createMutationMocks(mutationOverrides) {
  if (!Array.isArray(mutationOverrides)) {
    mutationOverrides = [mutationOverrides]
  }

  const mutationResult = await mockGraphqlQuery(
    UPDATE_COURSE_NOTIFICATION_PREFERENCES,
    mutationOverrides,
    {
      courseId: '1',
      channelId: '1',
      category: 'Grading',
      frequency: 'never',
    }
  )

  return [
    {
      request: {
        query: UPDATE_COURSE_NOTIFICATION_PREFERENCES,
        variables: {
          courseId: '1',
          channelId: '1',
          category: 'Grading',
          frequency: 'never',
        },
      },
      result: mutationResult,
    },
  ]
}

const mockedPrefs = {
  sendScoresInEmails: false,
  channels: [
    {
      _id: '1',
      path: 'test@example.com',
      pathType: 'email',
      categories: {
        courseActivities: {
          Grading: {
            communicationChannelId: '1',
            frequency: 'immediately',
          },
        },
      },
      notificationPolicies: [
        {
          communicationChannelId: '1',
          frequency: 'immediately',
          notification: {
            _id: '6',
            category: 'Grading',
            categoryDescription: 'Description Text',
            categoryDisplayName: 'Display Name Text',
            name: 'Assignment Graded',
          },
        },
      ],
      notificationPolicyOverrides: [],
    },
  ],
}

describe('Course Notification Settings', () => {
  it('displays the correct messaging for enabled notification settings', async () => {
    const mocks = await createQueryMocks({Node: {__typename: 'User'}})
    mocks[0].result.data.userLegacyNode.notificationPreferencesEnabled = true
    const {findByText, findByTestId} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AlertManager>
          <CourseNotificationSettingsQuery courseId="1" courseName="Super Cool Class" userId="1" />
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
    const mocks = await createQueryMocks({Node: {__typename: 'User'}})
    mocks[0].result.data.userLegacyNode.notificationPreferencesEnabled = false
    const {findByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AlertManager>
          <CourseNotificationSettingsQuery courseId="1" courseName="Super Cool Class" userId="1" />
        </AlertManager>
      </MockedProvider>
    )

    expect(
      await findByText(
        'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
      )
    ).toBeInTheDocument()
  })

  it('successfully calls the mutation when updating', async () => {
    ENV = {
      NOTIFICATION_PREFERENCES_OPTIONS: {
        send_scores_in_emails_text: {
          label: '',
        },
      },
    }
    const mocks = await createMutationMocks([
      {UpdateNotificationPreferencesPayload: {errors: null}},
    ])
    const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

    const {getByText, getAllByRole} = render(
      <AlertManagerContext.Provider
        value={{
          setOnSuccess: mockedSetOnSuccess,
        }}
      >
        <MockedProvider mocks={mocks}>
          <CourseNotificationSettingsManager
            courseId="1"
            userId="1"
            courseName="Course"
            enabled={true}
            notificationPreferences={mockedPrefs}
          />
        </MockedProvider>
      </AlertManagerContext.Provider>
    )

    const button = getAllByRole('button').pop()
    // Sanity check that we grabbed the correct button
    expect(button).toHaveTextContent('Notify immediately')
    fireEvent.click(button)
    fireEvent.click(getByText('Notifications off'))

    await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
  })
})

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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import ComposeModalManager from '../ComposeModalContainer/ComposeModalManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {setupServer} from 'msw/node'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as uploadFileModule from '@canvas/upload-file'
import {graphql, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/upload-file')

vi.mock('../../../util/utils', async () => ({
  ...(await vi.importActual('../../../util/utils')),
  responsiveQuerySizes: vi.fn().mockReturnValue({
    desktop: {minWidth: '768px'},
  }),
}))

describe('ComposeModalContainer - Include Observers Button', () => {
  const server = setupServer(...handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    server.close()
    server.listen({onUnhandledRequest: 'error'})

    window.matchMedia = vi.fn().mockImplementation(() => ({
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }))
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles.mockResolvedValue([])
    fakeENV.setup({
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1,
        CAN_MESSAGE_ACCOUNT_CONTEXT: true,
      },
    })
    server.use(
      graphql.query('GetConversationCourses', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              id: '1',
              __typename: 'User',
              enrollments: [
                {
                  id: '1',
                  type: 'TeacherEnrollment',
                  course: {
                    name: 'Fighting Magneto 101',
                    assetString: 'course_1',
                    id: '1',
                    __typename: 'Course',
                  },
                  __typename: 'Enrollment',
                },
              ],
              favoriteCoursesConnection: {
                nodes: [
                  {
                    name: 'Fighting Magneto 101',
                    assetString: 'course_1',
                    id: '1',
                    __typename: 'Course',
                  },
                ],
                __typename: 'CourseConnection',
              },
            },
          },
        })
      }),
    )
  })

  afterEach(async () => {
    server.resetHandlers()
    vi.clearAllTimers()
    vi.clearAllMocks()
    await waitForApolloLoading()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({setOnFailure = vi.fn(), setOnSuccess = vi.fn(), selectedIds = ['1']} = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
            <ComposeModalManager
              open={true}
              onDismiss={vi.fn()}
              onSelectedIdsChange={vi.fn()}
              selectedIds={selectedIds}
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

  it('should not render if context is not selected', async () => {
    const component = setup()
    await waitForApolloLoading()
    expect(component.container).toBeTruthy()
    expect(component.queryByTestId('include-observer-button')).toBeFalsy()
  })

  it('should render if context is selected', async () => {
    const component = render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
            <ComposeModalManager
              open={true}
              onDismiss={vi.fn()}
              selectedIds={['1']}
              onSelectedIdsChange={vi.fn()}
              activeCourseFilterID="course_1"
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

    await waitForApolloLoading()

    await waitFor(
      () => {
        const button = component.queryByTestId('include-observer-button')
        expect(button).toBeInTheDocument()
      },
      {timeout: 3000},
    )
  })

  it('should fetch all observers when button is clicked (single page)', async () => {
    const onSelectedIdsChange = vi.fn()

    server.use(
      graphql.query('GetRecipientsObservers', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              id: 'VXNlci0x',
              __typename: 'User',
              recipientsObservers: {
                nodes: [
                  {
                    id: 'observer_3',
                    name: 'Observer 1',
                    __typename: 'MessageableUser',
                    _id: '3',
                  },
                  {
                    id: 'observer_4',
                    name: 'Observer 2',
                    __typename: 'MessageableUser',
                    _id: '4',
                  },
                ],
                pageInfo: {
                  hasNextPage: false,
                  endCursor: null,
                  __typename: 'PageInfo',
                },
              },
            },
          },
        })
      }),
    )

    const component = render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
            <ComposeModalManager
              open={true}
              onDismiss={vi.fn()}
              selectedIds={[
                {id: 'user_1', _id: '1', name: 'Student 1'},
                {id: 'user_2', _id: '2', name: 'Student 2'},
              ]}
              onSelectedIdsChange={onSelectedIdsChange}
              activeCourseFilterID="course_1"
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

    await waitForApolloLoading()

    const button = await component.findByTestId('include-observer-button')
    expect(button).toBeInTheDocument()
    fireEvent.click(button)

    await waitFor(
      () => {
        expect(onSelectedIdsChange).toHaveBeenCalled()
        const callArgs =
          onSelectedIdsChange.mock.calls[onSelectedIdsChange.mock.calls.length - 1][0]
        expect(callArgs).toHaveLength(4)
        const observerIds = callArgs.map(r => r._id)
        expect(observerIds).toContain('3')
        expect(observerIds).toContain('4')
      },
      {timeout: 3000},
    )
  })

  it('should fetch all observers across multiple pages when button is clicked', async () => {
    let callCount = 0
    const onSelectedIdsChange = vi.fn()

    server.use(
      graphql.query('GetRecipientsObservers', ({variables}) => {
        callCount++

        if (!variables.after || variables.after === null) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                id: 'VXNlci0x',
                __typename: 'User',
                recipientsObservers: {
                  nodes: Array.from({length: 20}, (_, i) => ({
                    id: `observer_${i + 1}`,
                    name: `Observer ${i + 1}`,
                    __typename: 'MessageableUser',
                    _id: `${i + 1}`,
                  })),
                  pageInfo: {
                    hasNextPage: true,
                    endCursor: 'cursor1',
                    __typename: 'PageInfo',
                  },
                },
              },
            },
          })
        }

        if (variables.after === 'cursor1') {
          return HttpResponse.json({
            data: {
              legacyNode: {
                id: 'VXNlci0x',
                __typename: 'User',
                recipientsObservers: {
                  nodes: Array.from({length: 10}, (_, i) => ({
                    id: `observer_${i + 21}`,
                    name: `Observer ${i + 21}`,
                    __typename: 'MessageableUser',
                    _id: `${i + 21}`,
                  })),
                  pageInfo: {
                    hasNextPage: false,
                    endCursor: null,
                    __typename: 'PageInfo',
                  },
                },
              },
            },
          })
        }
      }),
    )

    const component = render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
            <ComposeModalManager
              open={true}
              onDismiss={vi.fn()}
              selectedIds={[
                {id: 'user_100', _id: '100', name: 'Student 1'},
                {id: 'user_101', _id: '101', name: 'Student 2'},
              ]}
              onSelectedIdsChange={onSelectedIdsChange}
              activeCourseFilterID="course_1"
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

    await waitForApolloLoading()

    const button = await component.findByTestId('include-observer-button')
    expect(button).toBeInTheDocument()
    fireEvent.click(button)

    await waitFor(
      () => {
        expect(onSelectedIdsChange).toHaveBeenCalled()
        expect(callCount).toBeGreaterThanOrEqual(2)

        const callArgs =
          onSelectedIdsChange.mock.calls[onSelectedIdsChange.mock.calls.length - 1][0]
        expect(callArgs).toHaveLength(32)

        const observerIds = callArgs.map(r => r._id)
        expect(observerIds).toContain('1')
        expect(observerIds).toContain('30')
      },
      {timeout: 5000},
    )
  })
})

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {render, fireEvent, screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {CreateOrEditSetModal} from '../index'

const server = setupServer()

// TODO: Fix timer cleanup issues causing "document is not defined" errors
// The Modal component uses transitions that leave pending timers after test teardown
describe.skip('CreateOrEditSetModal', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    server.resetHandlers()
  })

  it('should render the correct error message if the api call returns an errors object', async () => {
    const contextId = '1'
    const errorMessage =
      'An error occurred while creating the Group Set: doFetchApi received a bad response: 400 Bad Request'
    server.use(
      http.post(`/api/v1/accounts/${contextId}/group_categories`, () => {
        return HttpResponse.json(
          {
            errors: {
              name: [{message: errorMessage}],
            },
          },
          {status: 400},
        )
      }),
    )
    const {getByText, getAllByText, getByPlaceholderText} = render(
      <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />,
    )
    fireEvent.input(getByPlaceholderText('Enter Group Set Name'), {
      target: {value: 'name'},
    })
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(getAllByText(/error/i)[0].innerHTML).toContain(errorMessage)
    })
  })

  describe('small screen', () => {
    beforeEach(() => {
      window.matchMedia = vi.fn().mockImplementation(query => {
        return {
          matches: query.includes('(max-width: 600px)'),
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
        }
      })
    })

    it('renders components with column direction', () => {
      const {getByTestId} = render(<CreateOrEditSetModal allowSelfSignup={true} contextId="1" />)

      const groupSetName = getByTestId('group-name-controls')
      const groupSetNameStyle = getComputedStyle(groupSetName)
      expect(groupSetNameStyle.flexDirection).toBe('column')

      const groupStructure = getByTestId('group-structure-controls')
      const groupStructuretyle = getComputedStyle(groupStructure)
      expect(groupStructuretyle.flexDirection).toBe('column')

      const groupSelfSignUp = getByTestId('group-self-sign-up-controls')
      const groupSelfSignUpStyle = getComputedStyle(groupSelfSignUp)
      expect(groupSelfSignUpStyle.flexDirection).toBe('column')
    })
  })

  describe('not small screen', () => {
    beforeEach(() => {
      window.matchMedia = vi.fn().mockImplementation(query => {
        return {
          matches: !query.includes('(max-width: 600px)'),
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
        }
      })
    })

    it('renders components with row direction', () => {
      const {getByTestId} = render(<CreateOrEditSetModal allowSelfSignup={true} contextId="1" />)

      const groupSetName = getByTestId('group-name-controls')
      const groupSetNameStyle = getComputedStyle(groupSetName)
      expect(groupSetNameStyle.flexDirection).toBe('row')

      const groupStructure = getByTestId('group-structure-controls')
      const groupStructuretyle = getComputedStyle(groupStructure)
      expect(groupStructuretyle.flexDirection).toBe('row')

      const groupSelfSignUp = getByTestId('group-self-sign-up-controls')
      const groupSelfSignUpStyle = getComputedStyle(groupSelfSignUp)
      expect(groupSelfSignUpStyle.flexDirection).toBe('row')
    })
  })

  it('should call the group_categories api when self signup on', async () => {
    const contextId = '1'
    let groupCategoriesCalled = false
    let assignUnassignedCalled = false

    server.use(
      http.post(`/api/v1/accounts/${contextId}/group_categories`, () => {
        groupCategoriesCalled = true
        return HttpResponse.json({id: 1}, {status: 200})
      }),
      http.post('/api/v1/group_categories/1/assign_unassigned_members', () => {
        assignUnassignedCalled = true
        return HttpResponse.json({}, {status: 200})
      }),
    )

    const {getByText, getByPlaceholderText, getByTestId} = render(
      <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />,
    )
    fireEvent.input(getByPlaceholderText('Enter Group Set Name'), {
      target: {value: 'name'},
    })
    getByTestId('checkbox-allow-self-signup').click()
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(groupCategoriesCalled).toBe(true)
    })
    expect(assignUnassignedCalled).toBe(false)
  })

  it('should call the group_categories and assign_unassigned_members api when self signup off', async () => {
    const contextId = '1'
    let groupCategoriesCalled = false
    let assignUnassignedCalled = false

    server.use(
      http.post(`/api/v1/accounts/${contextId}/group_categories`, () => {
        groupCategoriesCalled = true
        return HttpResponse.json({id: 1}, {status: 200})
      }),
      http.post('/api/v1/group_categories/1/assign_unassigned_members', () => {
        assignUnassignedCalled = true
        return HttpResponse.json({}, {status: 200})
      }),
    )

    const {getByText, getByPlaceholderText, getByTestId} = render(
      <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />,
    )
    fireEvent.input(getByPlaceholderText('Enter Group Set Name'), {
      target: {value: 'name'},
    })
    getByTestId('group-structure-selector').click()
    await screen.getByTestId('group-structure-num-groups').click()
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(groupCategoriesCalled).toBe(true)
    })
    await waitFor(() => {
      expect(assignUnassignedCalled).toBe(true)
    })
  })
})

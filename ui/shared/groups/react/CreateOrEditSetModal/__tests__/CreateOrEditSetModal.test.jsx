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
import {render, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {CreateOrEditSetModal} from '../index'

describe('CreateOrEditSetModal', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('should render the correct error message if the api call returns an errors object', async () => {
    const contextId = '1'
    const errorMessage = 'fake response error message'
    fetchMock.postOnce(`post:/api/v1/accounts/${contextId}/group_categories`, {
      body: {
        errors: {
          name: [{message: errorMessage}],
        },
      },
      status: 400,
    })
    const {getByText, getAllByText, getByPlaceholderText} = render(
      <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />
    )
    fireEvent.input(getByPlaceholderText('Enter Group Set Name'), {
      target: {value: 'name'},
    })
    fireEvent.click(getByText('Save'))

    await fetchMock.flush(true)
    expect(getAllByText(/error/i)[0].innerHTML).toContain(errorMessage)
  })

  describe('small screen', () => {
    beforeEach(() => {
      window.matchMedia = jest.fn().mockImplementation(query => {
        return {
          matches: query.includes('(max-width: 600px)'),
          media: query,
          onchange: null,
          addListener: jest.fn(),
          removeListener: jest.fn(),
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
      window.matchMedia = jest.fn().mockImplementation(query => {
        return {
          matches: !query.includes('(max-width: 600px)'),
          media: query,
          onchange: null,
          addListener: jest.fn(),
          removeListener: jest.fn(),
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
})

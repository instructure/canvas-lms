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
    const errorMessage =
      'An error occurred while creating the Group Set: doFetchApi received a bad response: 400 Bad Request'
    fetchMock.postOnce(`post:/api/v1/accounts/${contextId}/group_categories`, {
      body: {
        errors: {
          name: [{message: errorMessage}],
        },
      },
      status: 400,
    })
    const {getByText, getAllByText, getByPlaceholderText} = render(
      <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />,
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

  describe('differentiation tags', () => {
    const originalEnv = window.ENV

    beforeEach(() => {
      window.ENV = {
        FEATURES: {
          differentiation_tags: true,
        },
      }
    })

    afterEach(() => {
      window.ENV = originalEnv
    })

    it('renders the differentiation tag checkbox when feature flag is enabled', () => {
      const {getByLabelText, getByText} = render(
        <CreateOrEditSetModal allowSelfSignup={true} contextId="1" />,
      )

      expect(getByLabelText('Is Differentiation Tag')).toBeInTheDocument()
      expect(
        getByText(
          'When enabled, this group set will be marked as a differentiation tag, and both self-signup and group structure options will be hidden.',
        ),
      ).toBeInTheDocument()
    })

    it('does not render the differentiation tag checkbox when feature flag is disabled', () => {
      window.ENV.FEATURES.differentiation_tags = false
      const {queryByLabelText} = render(
        <CreateOrEditSetModal allowSelfSignup={true} contextId="1" />,
      )

      expect(queryByLabelText('Is Differentiation Tag')).not.toBeInTheDocument()
    })

    it('hides self-signup and Group structure when differentiation tag is checked', () => {
      const {getByLabelText, queryByTestId} = render(
        <CreateOrEditSetModal allowSelfSignup={true} contextId="1" />,
      )

      const checkbox = getByLabelText('Is Differentiation Tag')
      fireEvent.click(checkbox)

      expect(queryByTestId('group-self-sign-up-controls')).not.toBeInTheDocument()
      expect(queryByTestId('group-structure-controls')).not.toBeInTheDocument()
    })

    it('includes non_collaborative flag in API payload when differentiation tag is checked', async () => {
      const contextId = '1'
      fetchMock.postOnce(`/api/v1/accounts/${contextId}/group_categories`, {
        status: 200,
        body: {},
      })

      const {getByLabelText, getByText, getByPlaceholderText} = render(
        <CreateOrEditSetModal allowSelfSignup={true} contextId={contextId} />,
      )

      // Fill required name field
      fireEvent.input(getByPlaceholderText('Enter Group Set Name'), {
        target: {value: 'Test Group'},
      })

      // Check differentiation tag
      const checkbox = getByLabelText('Is Differentiation Tag')
      fireEvent.click(checkbox)

      // Submit form
      fireEvent.click(getByText('Save'))

      await fetchMock.flush(true)
      const lastCall = fetchMock.lastCall()
      const requestBody = JSON.parse(lastCall[1].body)

      expect(requestBody.non_collaborative).toBe(true)
    })
  })
})

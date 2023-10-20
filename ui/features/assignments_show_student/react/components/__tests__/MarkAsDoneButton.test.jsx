/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import MarkAsDoneButton from '../MarkAsDoneButton'
import {SET_MODULE_ITEM_COMPLETION} from '@canvas/assignments/graphql/student/Mutations'

describe('"Mark as Done" button', () => {
  let onError
  let onToggle
  let props

  beforeEach(() => {
    onError = jest.fn()
    onToggle = jest.fn()

    props = {
      done: true,
      itemId: '123',
      moduleId: '456',
      onError,
      onToggle,
    }
  })

  const renderWithProvider = (overrides = {}, fail = false) => {
    const successfulResponse = {
      data: {
        setModuleItemCompletion: {
          moduleItem: {
            _id: 'a',
            __typename: 'ModuleItem',
          },
          __typename: 'SetModuleItemCompletionPayload',
          errors: null,
        },
      },
    }
    const failedResponse = {
      data: null,
      errors: 'sure, why not',
    }

    const variables = {done: false, itemId: '123', moduleId: '456'}
    const mocks = [
      {
        request: {query: SET_MODULE_ITEM_COMPLETION, variables},
        result: fail ? failedResponse : successfulResponse,
      },
    ]

    const propsToRender = {...props, ...overrides}

    return render(
      <MockedProvider mocks={mocks}>
        <MarkAsDoneButton {...propsToRender} />
      </MockedProvider>
    )
  }

  it('renders a button', async () => {
    const {getByRole} = renderWithProvider()
    expect(getByRole('button')).toBeInTheDocument()
  })

  it('shows the text "Mark as Done" if done is set to false', async () => {
    const {getByRole} = renderWithProvider({done: false})
    expect(getByRole('button')).toHaveTextContent('Mark as done')
  })

  it('shows the text "Done" if done is set to true', async () => {
    const {getByRole} = renderWithProvider()
    expect(getByRole('button')).toHaveTextContent('Done')
  })

  describe('clicking the button', () => {
    it('calls the SET_MODULE_ITEM_COMPLETION mutation', async () => {
      const {getByRole} = renderWithProvider()
      const button = getByRole('button')
      fireEvent.click(button)
      await waitFor(() => expect(getByRole('button')).toHaveTextContent('Mark as done'))
    })

    it('toggles the state of the button', async () => {
      const {getByRole} = renderWithProvider()
      const button = getByRole('button')
      fireEvent.click(button)
      await waitFor(() => expect(getByRole('button')).toHaveTextContent('Mark as done'))
    })

    it('calls the onToggle property', async () => {
      const {getByRole} = renderWithProvider()
      const button = getByRole('button')
      fireEvent.click(button)
      await waitFor(() => expect(onToggle).toHaveBeenCalled())
    })

    it('calls the onError property if an error occurs', async () => {
      const {getByRole} = renderWithProvider({}, true)
      const button = getByRole('button')
      fireEvent.click(button)
      await waitFor(() => expect(onError).toHaveBeenCalled())
    })
  })
})

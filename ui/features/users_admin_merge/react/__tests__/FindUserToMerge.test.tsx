/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent, render, screen} from '@testing-library/react'
import FindUserToMerge, {type FindUserToMergeProps} from '../FindUserToMerge'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {sourceUser, destinationUser, accountSelectOptions} from './test-data'

describe('FindUserToMerge', () => {
  const props: FindUserToMergeProps = {
    sourceUserId: sourceUser.id,
    accountSelectOptions,
    onFind: jest.fn(),
  }
  const createUserForMergeUrl = (userId: string) => `/users/${userId}/user_for_merge`
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  const renderComponent = (overrideProps?: Partial<FindUserToMergeProps>) => {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <FindUserToMerge {...props} {...overrideProps} />
      </MockedQueryClientProvider>,
    )
  }

  beforeEach(() => {
    fetchMock.get(createUserForMergeUrl(sourceUser.id), sourceUser, {overwriteRoutes: true})
  })

  it("should render the source user's name and email", async () => {
    renderComponent()
    const sourceUserText = await screen.findByText(`${sourceUser.name} (${sourceUser.email})`)

    expect(sourceUserText).toBeInTheDocument()
  })

  it('should not render the find by select if the user has no privilege to search by name', async () => {
    renderComponent({accountSelectOptions: []})
    await screen.findByText(`${sourceUser.name} (${sourceUser.email})`)
    const findBySelect = screen.queryByLabelText('Find by')

    expect(findBySelect).not.toBeInTheDocument()
  })

  describe('when the user is search by id', () => {
    it('should show an error if the user field is empty', async () => {
      renderComponent()
      const selectButton = await screen.findByLabelText('Select')

      await userEvent.click(selectButton)

      const errorMessage = screen.getByText('Required')
      expect(errorMessage).toBeInTheDocument()
    })

    it('should show an error if user choses oneself as destination user', async () => {
      renderComponent()
      const userId = await screen.findByLabelText('User ID *')
      const selectButton = await screen.findByLabelText('Select')

      fireEvent.change(userId, {target: {value: sourceUser.id}})
      await userEvent.click(selectButton)

      const errorMessage = await screen.findAllByText("You can't merge an account with itself.")
      expect(errorMessage.length).toBeTruthy()
    })

    it('should show an error if the user is not found', async () => {
      fetchMock.get(createUserForMergeUrl(destinationUser.id), 404, {
        overwriteRoutes: true,
      })
      renderComponent()
      const userId = await screen.findByLabelText('User ID *')
      const selectButton = await screen.findByLabelText('Select')

      fireEvent.change(userId, {target: {value: destinationUser.id}})
      await userEvent.click(selectButton)

      const errorMessage = await screen.findAllByText('No active user with that ID was found.')
      expect(errorMessage.length).toBeTruthy()
    })

    it('should show an error if failed to load the user for merge due to an unexpected error', async () => {
      fetchMock.get(createUserForMergeUrl(destinationUser.id), 500, {
        overwriteRoutes: true,
      })
      renderComponent()
      const userId = await screen.findByLabelText('User ID *')
      const selectButton = await screen.findByLabelText('Select')

      fireEvent.change(userId, {target: {value: destinationUser.id}})
      await userEvent.click(selectButton)

      const errorMessage = await screen.findAllByText(
        'Failed to load user to merge. Please try again later.',
      )
      expect(errorMessage.length).toBeTruthy()
    })

    it('should call onFind correctly if the form submission was successful', async () => {
      fetchMock.get(createUserForMergeUrl(destinationUser.id), destinationUser, {
        overwriteRoutes: true,
      })
      renderComponent()
      const userId = await screen.findByLabelText('User ID *')
      const selectButton = await screen.findByLabelText('Select')

      fireEvent.change(userId, {target: {value: destinationUser.id}})
      await userEvent.click(selectButton)

      expect(props.onFind).toHaveBeenCalledWith(destinationUser.id)
    })
  })

  describe('when the user is search by name', () => {
    beforeEach(async () => {
      renderComponent()
      // Wait for the source user data to load and the spinner to disappear
      await screen.findByText(`${sourceUser.name} (${sourceUser.email})`)
      const findBySelect = screen.getByLabelText('Find by')
      await userEvent.click(findBySelect)
      const nameOption = screen.getByRole('option', {
        name: 'Name',
      })
      await userEvent.click(nameOption)
    })

    it('should show an error if the user if field is empty', async () => {
      const selectButton = await screen.findByLabelText('Select')

      await userEvent.click(selectButton)

      const errorMessage = screen.getByText('Required')
      expect(errorMessage).toBeInTheDocument()
    })

    it('should call onFind correctly if the form submission was successful', async () => {
      fetchMock.get(createUserForMergeUrl(destinationUser.id), destinationUser, {
        overwriteRoutes: true,
      })
      const selectButton = await screen.findByLabelText('Select')
      const userId = await screen.findByLabelText('User *')

      fireEvent.change(userId, {target: {value: destinationUser.id}})
      await userEvent.click(selectButton)

      expect(props.onFind).toHaveBeenCalledWith(destinationUser.id)
    })
  })
})

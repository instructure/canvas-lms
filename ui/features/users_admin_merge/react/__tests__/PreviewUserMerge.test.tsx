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

import {render, screen} from '@testing-library/react'
import PreviewUserMerge, {type PreviewMergeProps} from '../PreviewUserMerge'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import {createUserToMergeQueryKey} from '../common'
import userEvent from '@testing-library/user-event'
import {sourceUser, destinationUser} from './test-data'
import {QueryClientProvider} from '@tanstack/react-query'

describe('PreviewUserMerge', () => {
  const props: PreviewMergeProps = {
    currentUserId: '1',
    sourceUserId: sourceUser.id,
    destinationUserId: destinationUser.id,
    onSwap: jest.fn(),
    onStartOver: jest.fn(),
  }
  const MERGE_USERS_URL = `/api/v1/users/${sourceUser.id}/merge_into/${destinationUser.id}`

  beforeAll(() => {
    // Unfortunately, toSorted is not supported in the current version of Node.js. This could be deleted once we are at Node.js v20.11.1
    Array.prototype.toSorted = function () {
      return this.sort((a, b) => a.localeCompare(b))
    }
  })

  beforeEach(() => {
    fetchMock.reset()
    // Pre-populating query cache so that it is more closely resembles the actual behavior.
    queryClient.setQueryData(createUserToMergeQueryKey(sourceUser.id), sourceUser)
    queryClient.setQueryData(createUserToMergeQueryKey(destinationUser.id), destinationUser)
  })

  const renderComponent = () =>
    render(
      <QueryClientProvider client={queryClient}>
        <PreviewUserMerge {...props} />
      </QueryClientProvider>,
    )

  it('should render the users data correctly', () => {
    renderComponent()

    const userToRemoveText = screen.getByText(
      `Source account ${sourceUser.name} (ID: ${sourceUser.id}) will be removed.`,
    )
    const targetUserToKeepText = screen.getByText(
      `Target account ${destinationUser.name} (ID: ${destinationUser.id}) will be kept.`,
    )
    const targetUserNameLink = screen.getByTestId('merged-user-link')
    const targetUserDisplayName = screen.getByTestId('merged-user-display-name')
    const targetUserSisId = screen.getByTestId('merged-user-sis-user-id')
    const targetUserLoginId = screen.getByTestId('merged-user-login-id')
    const targetUserIntegrationId = screen.getByTestId('merged-user-integration-id')
    const targetUserEmails = screen.getByTestId('merged-user-emails')
    const targetUserLogins = screen.getByTestId('merged-user-logins')
    const targetUserEnrollments = screen.getByTestId('merged-user-enrollments')
    expect(userToRemoveText).toBeInTheDocument()
    expect(targetUserToKeepText).toBeInTheDocument()
    expect(targetUserNameLink).toHaveTextContent(destinationUser.name)
    expect(targetUserNameLink).toHaveAttribute('href', `/users/${destinationUser.id}`)
    expect(targetUserDisplayName).toHaveTextContent(destinationUser.short_name!)
    expect(targetUserSisId).toHaveTextContent(destinationUser.sis_user_id!)
    expect(targetUserLoginId).toHaveTextContent(destinationUser.login_id!)
    expect(targetUserIntegrationId).toHaveTextContent(destinationUser.integration_id!)
    expect(targetUserEmails).toHaveTextContent(
      [...destinationUser.communication_channels, ...sourceUser.communication_channels]
        .toSorted()
        .map(email => (email === destinationUser.email ? `${email} (Default)` : email))
        .join(''),
    )
    expect(targetUserLogins).toHaveTextContent(
      [...destinationUser.pseudonyms, ...sourceUser.pseudonyms].toSorted().join(''),
    )
    expect(targetUserEnrollments).toHaveTextContent(
      [...destinationUser.enrollments, ...sourceUser.enrollments].toSorted().join(''),
    )
  })

  describe('when the destination user has no certain data', () => {
    it("should default to the source user's data", () => {
      queryClient.setQueryData(createUserToMergeQueryKey(destinationUser.id), {
        ...destinationUser,
        short_name: null,
        sis_user_id: null,
        login_id: null,
        integration_id: null,
      })
      renderComponent()

      const targetUserDisplayName = screen.getByTestId('merged-user-display-name')
      const targetUserSisId = screen.getByTestId('merged-user-sis-user-id')
      const targetUserLoginId = screen.getByTestId('merged-user-login-id')
      const targetUserIntegrationId = screen.getByTestId('merged-user-integration-id')
      expect(targetUserDisplayName).toHaveTextContent(sourceUser.short_name!)
      expect(targetUserSisId).toHaveTextContent(sourceUser.sis_user_id!)
      expect(targetUserLoginId).toHaveTextContent(sourceUser.login_id!)
      expect(targetUserIntegrationId).toHaveTextContent(sourceUser.integration_id!)
    })
  })

  describe('when the destination user has no certain data nor the source user', () => {
    it('should show placeholder', () => {
      queryClient.setQueryData(createUserToMergeQueryKey(sourceUser.id), {
        ...destinationUser,
        short_name: null,
        sis_user_id: null,
        login_id: null,
        integration_id: null,
      })
      queryClient.setQueryData(createUserToMergeQueryKey(destinationUser.id), {
        ...destinationUser,
        short_name: null,
        sis_user_id: null,
        login_id: null,
        integration_id: null,
      })
      renderComponent()

      const targetUserDisplayName = screen.getByTestId('merged-user-display-name')
      const targetUserSisId = screen.getByTestId('merged-user-sis-user-id')
      const targetUserLoginId = screen.getByTestId('merged-user-login-id')
      const targetUserIntegrationId = screen.getByTestId('merged-user-integration-id')
      expect(targetUserDisplayName).toHaveTextContent('-')
      expect(targetUserSisId).toHaveTextContent('-')
      expect(targetUserLoginId).toHaveTextContent('-')
      expect(targetUserIntegrationId).toHaveTextContent('-')
    })
  })

  it('should call onSwap when swap button is clicked', async () => {
    renderComponent()
    const swapButton = screen.getByLabelText('Swap Source and Target Accounts')

    await userEvent.click(swapButton)

    expect(props.onSwap).toHaveBeenCalled()
  })

  it('should call onStartOver with source user id', async () => {
    renderComponent()
    const startOverButton = screen.getByLabelText('Start Over with Source Account')

    await userEvent.click(startOverButton)

    expect(props.onStartOver).toHaveBeenCalledWith(sourceUser.id)
  })

  it('should call onStartOver with destination user id', async () => {
    renderComponent()
    const startOverButton = screen.getByLabelText('Start Over with Target Account')

    await userEvent.click(startOverButton)

    expect(props.onStartOver).toHaveBeenCalledWith(destinationUser.id)
  })

  describe('when merging users', () => {
    it('should show an success alert if the merge was successful', async () => {
      fetchMock.put(MERGE_USERS_URL, 204)
      renderComponent()
      const mergeButton = screen.getByLabelText('Merge Accounts')

      await userEvent.click(mergeButton)
      const confirmMergeButton = screen.getByLabelText('Merge User Accounts')
      await userEvent.click(confirmMergeButton)

      const successAlert = await screen.findAllByText(
        `User merge succeeded! ${sourceUser.name} and ${destinationUser.name} are now one and the same. Redirecting to the user's page...`,
      )
      expect(successAlert.length).toBeTruthy()
      expect(fetchMock.called(MERGE_USERS_URL)).toBe(true)
    })

    it('should show an error alert if the merge failed due to insufficient permissions', async () => {
      fetchMock.put(MERGE_USERS_URL, 403)
      renderComponent()
      const mergeButton = screen.getByLabelText('Merge Accounts')

      await userEvent.click(mergeButton)
      const confirmMergeButton = screen.getByLabelText('Merge User Accounts')
      await userEvent.click(confirmMergeButton)

      const errorAlert = await screen.findAllByText(
        'User merge failed. Please make sure you have proper permission and try again.',
      )
      expect(errorAlert.length).toBeTruthy()
      expect(fetchMock.called(MERGE_USERS_URL)).toBe(true)
    })

    it('should show and error alert if the merge failed for any other reason', async () => {
      fetchMock.put(MERGE_USERS_URL, 500)
      renderComponent()
      const mergeButton = screen.getByLabelText('Merge Accounts')

      await userEvent.click(mergeButton)
      const confirmMergeButton = screen.getByLabelText('Merge User Accounts')
      await userEvent.click(confirmMergeButton)

      const errorAlert = await screen.findAllByText('Failed to merge users. Please try again.')
      expect(errorAlert.length).toBeTruthy()
      expect(fetchMock.called(MERGE_USERS_URL)).toBe(true)
    })
  })
})

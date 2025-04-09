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
import MergeUsers, {type MergeUsersProps} from '../MergeUsers'
import fetchMock from 'fetch-mock'
import {User} from '../common'
import userEvent from '@testing-library/user-event'
import {accountSelectOptions, destinationUser, sourceUser} from './test-data'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {MemoryRouter, Route, Routes} from 'react-router-dom'

describe('MergeUsers', () => {
  const props: MergeUsersProps = {
    accountSelectOptions,
    currentUserId: '1',
  }
  const createUserForMergeUrl = (userId: string) => `/users/${userId}/user_for_merge`
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  const renderComponent = () => {
    return render(
      <MemoryRouter initialEntries={[`/users/${sourceUser.id}/admin_merge`]}>
        <Routes>
          <Route
            path="/users/:userId/admin_merge"
            element={
              <MockedQueryClientProvider client={queryClient}>
                <MergeUsers {...props} />
              </MockedQueryClientProvider>
            }
          />
        </Routes>
      </MemoryRouter>,
    )
  }

  const assertSourceAndDestinationUsers = async (sourceUser: User, destinationUser: User) => {
    expect(
      await screen.findByText(
        `Source account ${sourceUser.name} (ID: ${sourceUser.id}) will be removed.`,
      ),
    ).toBeInTheDocument()
    expect(
      await screen.findByText(
        `Target account ${destinationUser.name} (ID: ${destinationUser.id}) will be kept.`,
      ),
    ).toBeInTheDocument()
  }

  const assertSourceUser = async (sourceUser: User) => {
    const sourceUserText = await screen.findByText(`${sourceUser.name} (${sourceUser.email})`)

    expect(sourceUserText).toBeInTheDocument()
  }

  beforeAll(() => {
    // Unfortunately, toSorted is not supported in the current version of Node.js. This could be deleted once we are at Node.js v20.11.1
    Array.prototype.toSorted = function () {
      return this.sort((a, b) => a.localeCompare(b))
    }
  })

  beforeEach(async () => {
    fetchMock.get(createUserForMergeUrl(sourceUser.id), sourceUser, {overwriteRoutes: true})
    fetchMock.get(createUserForMergeUrl(destinationUser.id), destinationUser, {
      overwriteRoutes: true,
    })
    renderComponent()

    const userId = await screen.findByLabelText('User ID *')
    const selectButton = await screen.findByLabelText('Select')

    fireEvent.change(userId, {target: {value: destinationUser.id}})
    await userEvent.click(selectButton)
  })

  it('should be able to swap source and target user', async () => {
    assertSourceAndDestinationUsers(sourceUser, destinationUser)
    const swapButton = await screen.findByLabelText('Swap Source and Target Accounts')

    await userEvent.click(swapButton)

    assertSourceAndDestinationUsers(destinationUser, sourceUser)
  })

  it('should be able to start over with target user', async () => {
    const startOverButton = await screen.findByLabelText('Start Over with Target Account')

    await userEvent.click(startOverButton)

    await assertSourceUser(destinationUser)
  })

  it('should be able to start over with source user', async () => {
    const startOverButton = await screen.findByLabelText('Start Over with Source Account')

    await userEvent.click(startOverButton)

    await assertSourceUser(sourceUser)
  })
})

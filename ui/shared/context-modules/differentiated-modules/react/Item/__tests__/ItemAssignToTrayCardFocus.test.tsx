/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {cleanup, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {
  clearQueryCache,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  teardownEnv,
} from './ItemAssignToTrayTestUtils'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

describe('ItemAssignToTray - Card Focus', () => {
  beforeAll(() => {
    setupFlashHolder()
    server.listen({onUnhandledRequest: 'bypass'})
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    teardownEnv()
    clearQueryCache()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('focuses on the add button when deleting a card', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getAllByTestId} = renderComponent()

    const deleteButton = (await findAllByTestId('delete-card-button'))[0]
    await user.click(deleteButton)

    const addButton = getAllByTestId('add-card')[0]
    await waitFor(() => expect(addButton).toHaveFocus())
  })

  it("focuses on the newly-created card's delete button when adding a card", async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getByTestId, getAllByTestId} = renderComponent()

    // wait for the cards to render
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    const addButton = getAllByTestId('add-card')[0]
    await user.click(addButton)
    const deleteButtons = await findAllByTestId('delete-card-button')
    await waitFor(() =>
      expect(deleteButtons[deleteButtons.length - 1].closest('button')).toHaveFocus(),
    )
  })
})

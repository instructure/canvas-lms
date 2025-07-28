/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {statusColors} from '../../constants/colors'
import {render, within, cleanup} from '@testing-library/react'
import StatusesModal from '../StatusesModal'
import store from '../../stores/index'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Statuses Modal', () => {
  const originalState = store.getState()

  beforeEach(() => {
    fetchMock.mock('*', 200)
    fakeENV.setup({
      FEATURES: {
        extended_submission_state: true,
      },
    })
  })

  afterEach(() => {
    cleanup() // Clean up any rendered components
    store.setState(originalState, true)
    fetchMock.restore()
    fakeENV.teardown()
  })

  it('renders heading', () => {
    const onClose = jest.fn()
    const afterUpdateStatusColors = jest.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    const {getByRole} = within(document.body)
    expect(getByRole('heading', {name: /Statuses/i})).toBeTruthy()
  })

  it('renders six StatusColorListItems', () => {
    const onClose = jest.fn()
    const afterUpdateStatusColors = jest.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    const {getAllByRole} = within(document.body)
    expect(getAllByRole('listitem')).toHaveLength(6)
  })

  it('onClose is called when closed', async () => {
    const onClose = jest.fn()
    const afterUpdateStatusColors = jest.fn()

    const {getByRole} = render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    // Find the close button by its text content
    const closeButton = getByRole('button', {name: /Done/i})
    expect(closeButton).toBeInTheDocument()

    // Click the button and verify onClose was called
    await userEvent.click(closeButton)
    expect(onClose).toHaveBeenCalledTimes(1)
  })
})

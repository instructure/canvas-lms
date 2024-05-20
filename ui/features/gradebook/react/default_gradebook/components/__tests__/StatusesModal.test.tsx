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
import {render, within} from '@testing-library/react'
import StatusesModal from '../StatusesModal'
import store from '../../stores/index'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

describe('Statuses Modal', () => {
  beforeEach(() => {
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('renders heading', () => {
    const onClose = jest.fn()
    const afterUpdateStatusColors = jest.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />
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
      />
    )

    const {getAllByRole} = within(document.body)
    expect(getAllByRole('listitem').length).toBe(6)
  })

  it('onClose is called when closed', async () => {
    const onClose = jest.fn()
    const afterUpdateStatusColors = jest.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />
    )

    const {getByRole} = within(document.body)

    await userEvent.click(getByRole('button', {name: /Close/i}))
    expect(onClose).toHaveBeenCalledTimes(1)
  })
})

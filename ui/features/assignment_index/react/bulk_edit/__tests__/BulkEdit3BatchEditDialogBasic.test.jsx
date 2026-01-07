/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {fireEvent, screen} from '@testing-library/react'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import tokyo from 'timezone/Asia/Tokyo'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {vi} from 'vitest'
import {
  flushPromises,
  renderBulkEditAndWait,
  renderOpenBatchEditDialog,
} from './BulkEditBatchEditDialogTestUtils'

beforeEach(() => {
  fetchMock.put(/api\/v1\/courses\/\d+\/assignments\/bulk_update/, {})
  vi.useFakeTimers()
})

afterEach(() => {
  fetchMock.reset()
  vi.useRealTimers()
})

describe('Assignment Bulk Edit Dates - Basic Dialog', () => {
  const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null})

  beforeEach(() => {
    fakeENV.setup({
      TIMEZONE: 'Asia/Tokyo',
      FEATURES: {},
    })
    tzInTest.configureAndRestoreLater({
      tz: tz(tokyo, 'Asia/Tokyo'),
      tzData: {
        'Asia/Tokyo': tokyo,
      },
    })
  })

  afterEach(async () => {
    await flushPromises()
    fakeENV.teardown()
    tzInTest.restore()
  })

  it('displays an error alert if no assignments are selected', async () => {
    await renderBulkEditAndWait()
    const batchEditButton = await screen.findByText('Batch Edit')
    await user.click(batchEditButton)
    const errorMessage = await screen.findByText(
      'Use checkboxes to select one or more assignments to batch edit.',
    )
    expect(errorMessage).toBeInTheDocument()
  })

  it('can be canceled with no effects', async () => {
    const {getByText, queryByText, getByTestId} = await renderOpenBatchEditDialog()
    expect(getByText('Batch Edit Dates')).toBeInTheDocument()
    fireEvent.click(getByTestId('cancel-batch-edit'))
    vi.runAllTimers()
    expect(queryByText('Batch Edit Dates')).toBeNull()
  })

  it('clears days error when closing and reopening the dialog', async () => {
    const {queryByText, getByLabelText, getByTestId} = await renderOpenBatchEditDialog([1])
    fireEvent.change(getByLabelText('Days'), {target: {value: ''}})
    await user.click(queryByText('Confirm'))
    expect(queryByText('Number of days is required')).toBeInTheDocument()

    fireEvent.click(getByTestId('cancel-batch-edit'))
    vi.runAllTimers()

    fireEvent.click(queryByText('Batch Edit'))
    expect(queryByText('Batch Edit Dates')).toBeInTheDocument()
    expect(queryByText('Number of days is required')).not.toBeInTheDocument()
  })
})

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

import {render, fireEvent, screen} from '@testing-library/react'
import {DateRangeSelect, DateRangeSelectProps} from '../DateRangeSelect'
import {DATE_RANGE_TYPE_OPTIONS} from '../PermissionsModalUtils'

const defaultProps: DateRangeSelectProps = {
  dateRangeType: null,
  onChangeDateRangeType: jest.fn(),
  unlockAt: null,
  unlockAtDateInputRef: jest.fn(),
  unlockAtTimeInputRef: jest.fn(),
  unlockAtError: undefined,
  onChangeUnlockAt: jest.fn(),
  lockAt: null,
  lockAtDateInputRef: jest.fn(),
  lockAtTimeInputRef: jest.fn(),
  lockAtError: undefined,
  onChangeLockAt: jest.fn(),
}

const renderComponent = async (propsOverride: Partial<DateRangeSelectProps> = {}) => {
  const props = {...defaultProps, ...propsOverride}
  return render(<DateRangeSelect {...props} />)
}

describe('DateRangeSelect', () => {
  const unlockAtTestId = 'permissions-unlock-at'
  const lockAtTestId = 'permissions-lock-at'

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the start and end date inputs when dateRangeType is range', async () => {
    await renderComponent({dateRangeType: DATE_RANGE_TYPE_OPTIONS.range})
    const unlockAt = await screen.findByTestId(unlockAtTestId)
    const lockAt = await screen.findByTestId(lockAtTestId)

    expect(unlockAt).toBeInTheDocument()
    expect(lockAt).toBeInTheDocument()
  })

  it('renders the start date input when dateRangeType is start', async () => {
    await renderComponent({dateRangeType: DATE_RANGE_TYPE_OPTIONS.start})
    const unlockAt = await screen.findByTestId(unlockAtTestId)
    const lockAt = screen.queryByTestId(lockAtTestId)

    expect(unlockAt).toBeInTheDocument()
    expect(lockAt).toBeNull()
  })

  it('renders the end date input when dateRangeType is end', async () => {
    await renderComponent({dateRangeType: DATE_RANGE_TYPE_OPTIONS.end})
    const lockAt = await screen.findByTestId(lockAtTestId)
    const unlockAt = screen.queryByTestId(unlockAtTestId)

    expect(lockAt).toBeInTheDocument()
    expect(unlockAt).toBeNull()
  })

  it('calls onChangeDateRangeType when the select value changes', async () => {
    const propsOverride = {
      dateRangeType: DATE_RANGE_TYPE_OPTIONS.range,
      onChangeDateRangeType: jest.fn(),
    }
    await renderComponent(propsOverride)

    const select = await screen.findByLabelText('Set availability by')
    fireEvent.click(select)
    const option = await screen.findByText(DATE_RANGE_TYPE_OPTIONS.start.label)
    fireEvent.click(option)
    expect(propsOverride.onChangeDateRangeType).toHaveBeenCalled()
  })
})

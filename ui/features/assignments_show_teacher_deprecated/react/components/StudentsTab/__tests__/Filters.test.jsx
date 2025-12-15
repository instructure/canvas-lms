/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mockOverride} from '../../../test-utils'
import Filters from '../Filters'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

// These tests are skipped because InstUI Select v7+ doesn't open dropdowns properly in jsdom.
// The component itself notes that tests should be skipped until A2 work resumes.
describe.skip('choosing filter options', () => {
  const onChangeFunc = vi.fn()
  const override = mockOverride()

  beforeEach(() => {
    onChangeFunc.mockClear()
  })

  it('sends override ID when chosen in assignTo filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('assignToFilter'))
    await waitFor(() => {
      expect(getByText(override.title)).toBeInTheDocument()
    })
    await user.click(getByText(override.title))
    expect(onChangeFunc).toHaveBeenCalledWith('assignTo', override.lid)
  })

  it('sends null when everyone is chosen in assignTo filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('assignToFilter'))
    await waitFor(() => {
      expect(getByText('Everyone')).toBeInTheDocument()
    })
    await user.click(getByText('Everyone'))
    expect(onChangeFunc).toHaveBeenCalledWith('assignTo', null)
  })

  it('sends attempt number when specific attempt is chosen in attempt filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('attemptFilter'))
    await waitFor(() => {
      expect(getByText('Attempt 1')).toBeInTheDocument()
    })
    await user.click(getByText('Attempt 1'))
    expect(onChangeFunc).toHaveBeenCalledWith('attempt', 1)
  })

  it('sends null when all is chosen in attempt filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('attemptFilter'))
    await waitFor(() => {
      expect(getByText('All')).toBeInTheDocument()
    })
    await user.click(getByText('All'))
    expect(onChangeFunc).toHaveBeenCalledWith('attempt', null)
  })

  it('sends correct status when chosen in status filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('statusFilter'))
    await waitFor(() => {
      expect(getByText('Excused')).toBeInTheDocument()
    })
    await user.click(getByText('Excused'))
    expect(onChangeFunc).toHaveBeenCalledWith('status', 'excused')
  })

  it('sends null when all is chosen in status filter', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />,
    )
    await user.click(getByTestId('statusFilter'))
    await waitFor(() => {
      expect(getByText('All')).toBeInTheDocument()
    })
    await user.click(getByText('All'))
    expect(onChangeFunc).toHaveBeenCalledWith('status', null)
  })
})

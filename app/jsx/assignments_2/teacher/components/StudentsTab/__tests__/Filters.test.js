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
import {render, fireEvent} from '@testing-library/react'
import {mockOverride} from '../../../test-utils'
import Filters from '../Filters'

describe('choosing filter options', () => {
  const onChangeFunc = jest.fn()
  const override = mockOverride()

  it('sends override ID when chosen in assignTo filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('assignToFilter'))
    fireEvent.click(getByText(override.title))
    expect(onChangeFunc).toHaveBeenCalledWith('assignTo', override.lid)
  })

  it('sends null when everyone is chosen in assignTo filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('assignToFilter'))
    fireEvent.click(getByText('Everyone'))
    expect(onChangeFunc).toHaveBeenCalledWith('assignTo', null)
  })

  it('sends attempt number when specific attempt is chosen in attempt filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('attemptFilter'))
    fireEvent.click(getByText('Attempt 1'))
    expect(onChangeFunc).toHaveBeenCalledWith('attempt', 1)
  })

  it('sends null when all is chosen in attempt filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('attemptFilter'))
    fireEvent.click(getByText('All'))
    expect(onChangeFunc).toHaveBeenCalledWith('attempt', null)
  })

  it('sends correct status when chosen in status filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('statusFilter'))
    fireEvent.click(getByText('Excused'))
    expect(onChangeFunc).toHaveBeenCalledWith('status', 'excused')
  })

  it('sends null when all is chosen in status filter', () => {
    const {getByText, getByTestId} = render(
      <Filters overrides={[override]} numAttempts={2} onChange={onChangeFunc} />
    )
    fireEvent.click(getByTestId('statusFilter'))
    fireEvent.click(getByText('All'))
    expect(onChangeFunc).toHaveBeenCalledWith('status', null)
  })
})

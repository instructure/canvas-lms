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
import {fireEvent} from '@testing-library/react'
import renderWithMocks, {updateInternalSettingMutation} from './MockSettingsApi'
import StrandManager from '../StrandManager'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

const flushPromises = () => new Promise(setTimeout)

const fakeJob = {
  id: '1024',
  priority: 20,
  max_concurrent: 1,
  strand: 'foobar',
}

describe('StrandManager', () => {
  beforeAll(() => {
    doFetchApi.mockResolvedValue({status: 'OK', count: 1})
  })

  beforeEach(() => {
    doFetchApi.mockClear()
    updateInternalSettingMutation.mockClear()
  })

  it('edits priority but not concurrency for normal strand', async () => {
    const onUpdate = jest.fn()
    const {getByText, getByLabelText, queryByLabelText} = renderWithMocks(
      <StrandManager strand="foobar" jobs={[fakeJob]} onUpdate={onUpdate} />
    )
    fireEvent.click(getByText('Manage strand "foobar"', {selector: 'button span'}))
    expect(queryByLabelText('Dynamic concurrency')).not.toBeInTheDocument()
    expect(queryByLabelText('Permanent num_strands setting')).not.toBeInTheDocument()
    fireEvent.change(getByLabelText('Priority'), {target: {value: '11'}})
    fireEvent.click(getByText('Apply'))
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/jobs2/manage',
      method: 'PUT',
      params: {strand: 'foobar', priority: 11, max_concurrent: 1},
    })
    await flushPromises()
    expect(onUpdate).toHaveBeenCalledWith({status: 'OK', count: 1})
  })

  it('edits both priority and concurrency for n_strand', async () => {
    const onUpdate = jest.fn()
    const {getByText, getByLabelText} = renderWithMocks(
      <StrandManager strand="foobar" jobs={[{...fakeJob, max_concurrent: 2}]} onUpdate={onUpdate} />
    )
    await flushPromises()
    fireEvent.click(getByText('Manage strand "foobar"', {selector: 'button span'}))
    fireEvent.change(getByLabelText('Priority'), {target: {value: '11'}})
    fireEvent.change(getByLabelText('Dynamic concurrency'), {target: {value: '7'}})
    fireEvent.change(getByLabelText('Permanent num_strands setting'), {target: {value: '14'}})
    fireEvent.click(getByText('Apply'))
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/jobs2/manage',
      method: 'PUT',
      params: {strand: 'foobar', priority: 11, max_concurrent: 7},
    })
    await flushPromises()
    expect(onUpdate).toHaveBeenCalledWith({status: 'OK', count: 1})
    expect(updateInternalSettingMutation).toHaveBeenCalled()
  })

  it("doesn't mutate the num_strands setting if unchanged", async () => {
    const onUpdate = jest.fn()
    const {getByText, getByLabelText} = renderWithMocks(
      <StrandManager strand="foobar" jobs={[{...fakeJob, max_concurrent: 2}]} onUpdate={onUpdate} />
    )
    await flushPromises()
    fireEvent.click(getByText('Manage strand "foobar"', {selector: 'button span'}))
    fireEvent.change(getByLabelText('Priority'), {target: {value: '15'}})
    fireEvent.change(getByLabelText('Dynamic concurrency'), {target: {value: '8'}})
    fireEvent.click(getByText('Apply'))
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/jobs2/manage',
      method: 'PUT',
      params: {strand: 'foobar', priority: 15, max_concurrent: 8},
    })
    await flushPromises()
    expect(onUpdate).toHaveBeenCalledWith({status: 'OK', count: 1})
    expect(updateInternalSettingMutation).not.toHaveBeenCalled()
  })
})

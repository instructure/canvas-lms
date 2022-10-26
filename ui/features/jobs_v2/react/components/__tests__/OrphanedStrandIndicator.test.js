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
import {render, fireEvent} from '@testing-library/react'
import OrphanedStrandIndicator from '../OrphanedStrandIndicator'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

const flushPromises = () => new Promise(setTimeout)

function mockUnstuckApi({path, params}) {
  if (path === '/api/v1/jobs2/unstuck') {
    if (params.strand) {
      return Promise.resolve({json: {status: 'OK', count: 2}})
    } else if (params.singleton) {
      return Promise.resolve({json: {status: 'OK', count: 1}})
    } else {
      return Promise.resolve({
        json: {
          status: 'pending',
          progress: {
            id: 101,
            url: 'http://example.com/api/v1/progress/101',
            workflow_state: 'queued',
          },
        },
      })
    }
  } else {
    return Promise.reject()
  }
}

describe('OrphanedStrandIndicator', () => {
  let oldEnv
  beforeAll(() => {
    oldEnv = {...window.ENV}
    doFetchApi.mockImplementation(mockUnstuckApi)
  })

  beforeEach(() => {
    doFetchApi.mockClear()
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  it("doesn't render button if the user lacks :manage_jobs", async () => {
    ENV.manage_jobs = false
    const {queryByText} = render(
      <OrphanedStrandIndicator name="strandy" type="strand" onComplete={jest.fn()} />
    )
    expect(queryByText('Unblock strand "strandy"')).not.toBeInTheDocument()
  })

  it('unstucks a strand', async () => {
    ENV.manage_jobs = true
    const onComplete = jest.fn()
    const {getByText} = render(
      <OrphanedStrandIndicator name="strandy" type="strand" onComplete={onComplete} />
    )
    fireEvent.click(getByText('Unblock strand "strandy"'))
    fireEvent.click(getByText('Unblock'))
    await flushPromises()
    expect(onComplete).toHaveBeenCalledWith({status: 'OK', count: 2})
  })

  it('unstucks a singleton', async () => {
    ENV.manage_jobs = true
    const onComplete = jest.fn()
    const {getByText} = render(
      <OrphanedStrandIndicator name="tony" type="singleton" onComplete={onComplete} />
    )
    fireEvent.click(getByText('Unblock singleton "tony"'))
    fireEvent.click(getByText('Unblock'))
    await flushPromises()
    expect(onComplete).toHaveBeenCalledWith({status: 'OK', count: 1})
  })
})

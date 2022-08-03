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
import RequeueButton from '../RequeueButton'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

const flushPromises = () => new Promise(setTimeout)

function mockRequeueApi({path}) {
  if (path === '/api/v1/jobs2/1/requeue') {
    return Promise.resolve({json: {id: 123}})
  } else {
    return Promise.reject()
  }
}

describe('RequeueButton', () => {
  let oldEnv
  beforeAll(() => {
    oldEnv = {...window.ENV}
    doFetchApi.mockImplementation(mockRequeueApi)
  })

  beforeEach(() => {
    doFetchApi.mockClear()
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  it("doesn't render if the user lacks :manage_jobs", async () => {
    ENV.manage_jobs = false
    const {queryByText} = render(<RequeueButton id="1" onRequeue={jest.fn()} />)
    expect(queryByText('Requeue Job')).not.toBeInTheDocument()
  })

  it('initiates a requeue if the user has :manage_jobs', async () => {
    ENV.manage_jobs = true
    const onRequeue = jest.fn()
    const {getByRole} = render(<RequeueButton id="1" onRequeue={onRequeue} />)
    fireEvent.click(getByRole('button', {name: 'Requeue Job'}))
    await flushPromises()
    expect(onRequeue).toHaveBeenCalledWith({id: 123})
  })
})

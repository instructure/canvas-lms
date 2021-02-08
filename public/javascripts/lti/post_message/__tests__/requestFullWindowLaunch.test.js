/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import handler from '../requestFullWindowLaunch'

describe('requestFullWindowLaunch', () => {
  const {assign} = window.location

  beforeEach(() => {
    delete window.location
    window.location = {assign: jest.fn(), origin: 'http://localhost'}
  })

  afterEach(() => {
    window.location.assign = assign
  })

  it('opens new window on requestFullWindowLaunch', () => {
    ENV.context_asset_string = 'account_1'
    handler('http://localhost/test')
    expect(window.location.assign).toHaveBeenCalled()
  })

  it('pulls out client_id if provided', () => {
    ENV.context_asset_string = 'account_1'
    handler('http://localhost/test?client_id=hello')
    const launch_url = new URL(window.location.assign.mock.calls[0][0])
    expect(launch_url.searchParams.get('client_id')).toEqual('hello')
  })
})

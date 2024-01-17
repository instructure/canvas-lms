/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import * as CanvasApollo from '@canvas/apollo'
import NotificationSettings from '../index'

// VICE-4065 - remove or rewrite to remove spies on CanvasApollo import
// we may want to delete this test anyway
describe.skip('AccountNotificationSettings', () => {
  afterAll(() => {
    jest.restoreAllMocks()
    jest.resetModules()
  })

  it('can be configured for api gateway access', () => {
    jest.spyOn(CanvasApollo, 'createClient')
    const fakeEnv = {
      API_GATEWAY_URI: 'http://some-gateway.api/graphql',
      DOMAIN_ROOT_ACCOUNT_ID: '12345',
      current_user_id: '54321',
    }
    NotificationSettings({envDict: fakeEnv})
    expect(CanvasApollo.createClient).toHaveBeenCalledWith({
      apiGatewayUri: 'http://some-gateway.api/graphql',
    })
  })
})

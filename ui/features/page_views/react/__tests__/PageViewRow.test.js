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

import React from 'react'
import {mount} from 'enzyme'
import PageViewRow from '../PageViewRow'

const defaultData = (data = {}) => ({
  action: 'show',
  app_name: null,
  asset_type: null,
  asset_user_access_id: '12345',
  context_type: 'Course',
  contributed: false,
  controller: 'assignments',
  created_at: '2021-12-03T07:51:27Z',
  developer_key_id: null,
  http_method: 'get',
  id: 'b45b74de-19fd-4178-b677-9957ec76b476',
  interaction_seconds: null,
  links: {user: 1, context: 1234, asset: null, real_user: null, account: 1},
  participated: false,
  remote_ip: '127.0.0.1',
  render_time: 0.78121,
  session_id: '58cb2c11111cd5a1b8a999fbe999ea',
  summarized: null,
  updated_at: '2021-12-03T07:51:27Z',
  url: 'https://canvas.local/',
  user_agent:
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36',
  user_request: null,
  ...data
})

const EDGE_USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/12.246'
const CHROME_USER_AGENT =
  'Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64'
const SAFARI_USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9'
const SPEEDGRADER_USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Speedgrader/1.3'

describe('user agents', () => {
  it('edge', () => {
    const wrapper = mount(<PageViewRow data={defaultData()} />)
    expect(wrapper.instance().parseUserAgentString(EDGE_USER_AGENT)).toEqual('Edge 12')
  })

  it('chrome', () => {
    const wrapper = mount(<PageViewRow data={defaultData()} />)
    expect(wrapper.instance().parseUserAgentString(CHROME_USER_AGENT)).toEqual('Chrome 51')
  })

  it('safari', () => {
    const wrapper = mount(<PageViewRow data={defaultData()} />)
    expect(wrapper.instance().parseUserAgentString(SAFARI_USER_AGENT)).toEqual('Safari 9')
  })

  it('speedgrader', () => {
    const wrapper = mount(<PageViewRow data={defaultData()} />)
    expect(wrapper.instance().parseUserAgentString(SPEEDGRADER_USER_AGENT)).toEqual(
      'SpeedGrader for iPad'
    )
  })
})

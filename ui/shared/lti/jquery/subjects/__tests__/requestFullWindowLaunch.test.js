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

import {assignLocation, openWindow} from '@canvas/util/globalUtils'
import handler from '../requestFullWindowLaunch'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
  openWindow: jest.fn(),
}))

describe('requestFullWindowLaunch', () => {
  beforeEach(() => {
    ENV.context_asset_string = 'account_1'
    window.location = {
      origin: 'http://localhost',
      toString: () => 'http://localhost/',
    }
    window.open = jest.fn()
  })

  describe('with string provided', () => {
    it('uses launch type same_window', () => {
      handler({message: {data: 'http://localhost/test'}})
      expect(assignLocation).toHaveBeenCalled()
    })

    it('pulls out client_id if provided', () => {
      handler({message: {data: 'http://localhost/test?client_id=hello'}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fclient_id%3Dhello%26platform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1&client_id=hello',
      )
    })

    it('pulls out assignment_id if provided', () => {
      handler({message: {data: 'http://localhost/test?client_id=hello&assignment_id=50'}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fclient_id%3Dhello%26assignment_id%3D50%26platform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1&client_id=hello&assignment_id=50',
      )
    })
  })

  describe('with object provided', () => {
    it('must contain a `url` property', () => {
      expect(() => handler({message: {data: {}}})).toThrow()
    })

    it('uses launch type same_window by default', () => {
      handler({message: {data: {url: 'http://localhost/test'}}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
      )
    })

    it('opens launch type new_window in a new tab', () => {
      handler({message: {data: {url: 'http://localhost/test', launchType: 'new_window'}}})
      expect(openWindow).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
        'newWindowLaunch',
      )
    })

    it('opens launch type popup in a popup window', () => {
      handler({message: {data: {url: 'http://localhost/test', launchType: 'popup'}}})
      expect(openWindow).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
        'popupLaunch',
        expect.stringMatching(/toolbar=no.*width=800,height=600/),
      )
    })

    it('errors on unknown launch type', () => {
      expect(() =>
        handler({message: {data: {url: 'http://localhost/test', launchType: 'unknown'}}}),
      ).toThrow()
    })

    it('uses placement to add to launch url', () => {
      handler({message: {data: {url: 'http://localhost/test', placement: 'course_navigation'}}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1&placement=course_navigation',
      )
    })

    it('uses launchOptions to add width and height to popup', () => {
      handler({
        message: {
          data: {
            url: 'http://localhost/test',
            launchType: 'popup',
            launchOptions: {
              width: 420,
              height: 400,
            },
          },
        },
      })
      expect(openWindow).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
        'popupLaunch',
        expect.stringMatching(/toolbar=no.*width=420,height=400/),
      )
    })

    it('uses display type borderless by default', () => {
      handler({message: {data: {url: 'http://localhost/test'}}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
      )
    })

    it('allows display type to be overridden', () => {
      handler({message: {data: {url: 'http://localhost/test', display: 'full_width_in_context'}}})
      expect(assignLocation).toHaveBeenCalledWith(
        'http://localhost/accounts/1/external_tools/retrieve?display=full_width_in_context&url=http%3A%2F%2Flocalhost%2Ftest%3Fplatform_redirect_url%3Dhttp%253A%252F%252Flocalhost%252F%26full_win_launch_requested%3D1',
      )
    })
  })

  describe('with anything other than a string or object provided', () => {
    it('errors', () => {
      expect(() => handler({message: {data: ['foo', 'bar']}})).toThrow(
        'message contents must either be a string or an object',
      )
    })
  })
})

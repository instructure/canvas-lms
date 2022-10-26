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
  const open = window.open

  beforeEach(() => {
    delete window.open
    delete window.location
    window.location = {assign: jest.fn(), origin: 'http://localhost'}
    window.open = jest.fn()
    ENV.context_asset_string = 'account_1'
  })

  afterEach(() => {
    window.location.assign = assign
    window.open = open
  })

  describe('with string provided', () => {
    it('uses launch type same_window', () => {
      handler({message: {data: 'http://localhost/test'}})
      expect(window.location.assign).toHaveBeenCalled()
    })

    it('pulls out client_id if provided', () => {
      handler({message: {data: 'http://localhost/test?client_id=hello'}})
      const launch_url = new URL(window.location.assign.mock.calls[0][0])
      expect(launch_url.searchParams.get('client_id')).toEqual('hello')
    })

    it('pulls out assignment_id if provided', () => {
      handler({message: {data: 'http://localhost/test?client_id=hello&assignment_id=50'}})
      const launch_url = new URL(window.location.assign.mock.calls[0][0])
      expect(launch_url.searchParams.get('assignment_id')).toEqual('50')
    })
  })

  describe('with object provided', () => {
    it('must contain a `url` property', () => {
      expect(() => handler({message: {data: {foo: 'bar'}}})).toThrow(
        'message must contain a `url` property'
      )
    })

    it('uses launch type same_window by default', () => {
      handler({message: {data: {url: 'http://localhost/test'}}})
      expect(window.location.assign).toHaveBeenCalled()
    })

    it('opens launch type new_window in a new tab', () => {
      handler({message: {data: {url: 'http://localhost/test', launchType: 'new_window'}}})
      expect(window.open).toHaveBeenCalled()
    })

    it('opens launch type popup in a popup window', () => {
      handler({message: {data: {url: 'http://localhost/test', launchType: 'popup'}}})
      expect(window.open).toHaveBeenCalledWith(
        expect.any(String),
        'popupLaunch',
        expect.stringMatching(/toolbar/)
      )
    })

    it('errors on unknown launch type', () => {
      expect(() =>
        handler({message: {data: {url: 'http://localhost/test', launchType: 'fake'}}})
      ).toThrow("unknown launchType, must be 'popup', 'new_window', 'same_window'")
    })

    it('uses placement to add to launch url', () => {
      handler({message: {data: {url: 'http://localhost/test', placement: 'course_navigation'}}})
      expect(window.location.assign).toHaveBeenCalledWith(
        expect.stringContaining('&placement=course_navigation')
      )
    })

    it('uses launchOptions to add width and height to popup', () => {
      handler({
        message: {
          data: {
            url: 'http://localhost/test',
            launchType: 'popup',
            launchOptions: {width: 420, height: 400},
          },
        },
      })
      expect(window.open).toHaveBeenCalledWith(
        expect.any(String),
        'popupLaunch',
        expect.stringContaining('width=420,height=400')
      )
    })

    it('uses display type borderless by default', () => {
      handler({message: {data: {url: 'http://localhost/test'}}})
      const launch_url = new URL(window.location.assign.mock.calls[0][0])
      expect(launch_url.searchParams.get('display')).toEqual('borderless')
    })

    it('allows display type to be overridden', () => {
      handler({message: {data: {url: 'http://localhost/test', display: 'full_width_in_context'}}})
      const launch_url = new URL(window.location.assign.mock.calls[0][0])
      expect(launch_url.searchParams.get('display')).toEqual('full_width_in_context')
    })
  })

  describe('with anything other than a string or object provided', () => {
    it('errors', () => {
      expect(() => handler({message: {data: ['foo', 'bar']}})).toThrow(
        'message contents must either be a string or an object'
      )
    })
  })
})

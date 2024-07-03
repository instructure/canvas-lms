/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import getPageSettings from '../lti.getPageSettings'

describe('lti.getPageSettings handler', () => {
  let responseMessages
  let originalEnv
  let actualSettings
  let expectedSettings

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendResponse: jest.fn(),
      sendError: jest.fn(),
    }
    originalEnv = window.ENV
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  function expectSettings() {
    window.ENV = actualSettings
    expect(getPageSettings({responseMessages})).toEqual(true)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith({pageSettings: expectedSettings})
    expect(responseMessages.sendResponse).toHaveBeenCalledTimes(1)
    expect(responseMessages.sendError).not.toHaveBeenCalled()
  }

  describe('when ENV has no keys', () => {
    beforeEach(() => {
      actualSettings = {}
      expectedSettings = {
        locale: '',
        time_zone: '',
        use_high_contrast: false,
        active_brand_config_json_url: '',
        window_width: 1024,
      }
    })

    it('returns default settings', () => {
      expectSettings()
    })
  })

  describe('when ENV has all keys', () => {
    beforeEach(() => {
      actualSettings = {
        LOCALE: 'en',
        TIMEZONE: 'America/New_York',
        use_high_contrast: true,
        active_brand_config_json_url: 'http://example.com/config.json',
      }
      expectedSettings = {
        locale: 'en',
        time_zone: 'America/New_York',
        use_high_contrast: true,
        active_brand_config_json_url: 'http://example.com/config.json',
        window_width: 1024,
      }
    })

    it('includes all settings', () => {
      expectSettings()
    })
  })

  describe('when ENV has partial keys', () => {
    beforeEach(() => {
      actualSettings = {
        LOCALE: 'en',
      }
      expectedSettings = {
        locale: 'en',
        time_zone: '',
        use_high_contrast: false,
        active_brand_config_json_url: '',
        window_width: 1024,
      }
    })

    it('includes present settings with missing defaults', () => {
      expectSettings()
    })
  })
})

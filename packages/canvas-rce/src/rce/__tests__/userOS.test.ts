// @ts-nocheck
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

import {determineUserOS, determineOSDependentKey} from '../userOS'

const enum UserAgent {
  MAC = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:103.0) Gecko/20100101 Firefox/103.0',
  WINDOWS = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',
  LINUX = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36',
}

describe('userOS', () => {
  let userAgentSpy

  beforeAll(() => {
    userAgentSpy = jest.spyOn(window.navigator, 'userAgent', 'get')
  })

  afterAll(() => {
    jest.restoreAllMocks()
  })

  describe('when the user is running a Mac OS', () => {
    beforeEach(() => {
      userAgentSpy.mockReturnValue(UserAgent.MAC)
    })

    it('determineUserOS returns Mac', () => {
      expect(determineUserOS()).toEqual('Mac')
    })

    it('determineOSDependentKey returns the correct value', () => {
      expect(determineOSDependentKey()).toEqual('OPTION')
    })
  })

  describe('when the user is running a Windows OS', () => {
    beforeEach(() => {
      userAgentSpy.mockReturnValue(UserAgent.WINDOWS)
    })

    it('determineUserOS returns Windows', () => {
      expect(determineUserOS()).toEqual('Windows')
    })

    it('determineOSDependentKey returns the correct value', () => {
      expect(determineOSDependentKey()).toEqual('ALT')
    })
  })

  describe('when the user is running something other than Mac or Windows', () => {
    beforeEach(() => {
      userAgentSpy.mockReturnValue(UserAgent.LINUX)
    })

    it('determineUserOS returns Other', () => {
      expect(determineUserOS()).toEqual('Other')
    })

    it('determineOSDependentKey returns the correct value', () => {
      expect(determineOSDependentKey()).toEqual('ALT')
    })
  })
})

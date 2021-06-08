/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {matchingToolUrls} from '../LtiAssignmentHelpers'

describe('#matchingToolUrls', () => {
  let firstUrl
  let secondUrl

  const subject = () => matchingToolUrls(firstUrl, secondUrl)

  describe('when domains and protocol match', () => {
    beforeEach(() => {
      firstUrl = 'https://www.mytool.com/blti'
      secondUrl = 'https://www.mytool.com/blti/resourceid'
    })

    it('returns true', () => {
      expect(subject()).toEqual(true)
    })
  })

  describe('when domains match but protocols do not', () => {
    beforeEach(() => {
      firstUrl = 'http://www.mytool.com/blti'
      secondUrl = 'https://www.mytool.com/blti/resourceid'
    })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when domains do not match but protocols do', () => {
    beforeEach(() => {
      firstUrl = 'https://www.mytool.com/blti'
      secondUrl = 'https://www.other-tool.com/blti'
    })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when neither domain nor protocols match', () => {
    beforeEach(() => {
      firstUrl = 'https://www.mytool.com/blti'
      secondUrl = 'http://www.other-tool.com/blti'
    })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the first url is falsey', () => {
    beforeEach(() => {
      firstUrl = undefined
      secondUrl = 'https://www.other-tool.com/blti'
    })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the last url is falsey', () => {
    beforeEach(() => {
      firstUrl = 'https://www.mytool.com/blti'
      secondUrl = undefined
    })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })
})

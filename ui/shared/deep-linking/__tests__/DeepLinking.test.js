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

import {isValidDeepLinkingEvent} from '../DeepLinking'

describe('isValidDeepLinkingEvent', () => {
  let data, event, env, parameters

  beforeEach(() => {
    event = {data: {messageType: 'LtiDeepLinkingResponse'}, origin: 'canvas.instructure.com'}
    env = {DEEP_LINKING_POST_MESSAGE_ORIGIN: 'canvas.instructure.com'}
    parameters = [event, env]
  })

  const subject = () => isValidDeepLinkingEvent(...parameters)

  it('return true', () => {
    expect(subject()).toEqual(true)
  })

  describe('when the message origin is incorrect', () => {
    beforeEach(() => {
      event = {data, origin: 'wrong.origin.com'}
      parameters = [event, env]
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the event data is not present', () => {
    beforeEach(() => {
      event = {origin: 'canvas.instructure.com'}
      parameters = [event, env]
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })

  describe('when the messageType is incorrect', () => {
    beforeEach(() => {
      event = {data: {messageType: 'WrongMessageType'}, origin: 'canvas.instructure.com'}
      parameters = [event, env]
    })

    it('return false', () => {
      expect(subject()).toEqual(false)
    })
  })
})

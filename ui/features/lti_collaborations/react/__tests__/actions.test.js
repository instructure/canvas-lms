/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import actions from '../actions'

import axios from '@canvas/axios'

describe('actions', () => {
  let oldEnvContextAssetString

  beforeEach(() => {
    oldEnvContextAssetString = ENV.context_asset_string
    ENV.context_asset_string = 'course_1'
  })

  afterEach(() => {
    ENV.context_asset_string = oldEnvContextAssetString
  })

  const mockDispatch = arg => (typeof arg === 'function' ? arg(mockDispatch) : arg)

  describe('externalContentReady', () => {
    describe('when service_id (collaboration id) is given', () => {
      it('constructs the update URL with the context and service_id and includes contentItems and tool_id', () => {
        jest.spyOn(axios, 'put').mockImplementation(() => Promise.resolve())
        actions.externalContentReady({
          service_id: 123,
          tool_id: 1234,
          contentItems: [{item: 'foo'}],
        })(mockDispatch)
        expect(axios.put).toHaveBeenCalledWith(
          '/courses/1/collaborations/123',
          {
            contentItems: JSON.stringify([{item: 'foo'}]),
            tool_id: 1234,
          },
          expect.anything()
        )
      })
    })
  })

  describe('when service_id (collaboration id) is not given', () => {
    it('constructs the create URL with the context and includes contentItems and tool_id', () => {
      jest.spyOn(axios, 'post').mockImplementation(() => Promise.resolve())
      actions.externalContentReady({
        tool_id: 1234,
        contentItems: [{item: 'foo'}],
      })(mockDispatch)
      expect(axios.post).toHaveBeenCalledWith(
        '/courses/1/collaborations',
        {
          contentItems: JSON.stringify([{item: 'foo'}]),
          tool_id: 1234,
        },
        expect.anything()
      )
    })
  })
})

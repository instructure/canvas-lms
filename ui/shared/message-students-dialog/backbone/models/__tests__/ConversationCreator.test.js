/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import ConversationCreator from '../ConversationCreator'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)
const strictEqual = (value, expected) => expect(value).toEqual(expected)

let cc
const mockHandler = jest.fn()

const server = setupServer(
  http.post('/api/v1/conversations', () => {
    mockHandler()
    return HttpResponse.json({})
  }),
)

describe('ConversationCreator', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    mockHandler.mockClear()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    cc = new ConversationCreator({chunkSize: 2})
  })

  test('#validate passes through to Conversation', function () {
    ok(cc.validate({body: ''}))
    ok(cc.validate({body: null}).body)
    strictEqual(
      cc.validate({
        body: 'body',
        recipients: [{}],
      }),
      undefined,
    )
  })

  test('#save calls save in batches', async function () {
    const dfd = cc.save({
      body: 'body',
      recipients: [1, 2, 3, 4],
    })
    equal(dfd.state(), 'pending')
    await dfd
    equal(dfd.state(), 'resolved')
    expect(mockHandler).toHaveBeenCalledTimes(2)
  })
})

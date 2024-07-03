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

import 'jquery-migrate'
import Conversation from '../Conversation'

let conversation

describe('Conversation', () => {
  beforeEach(() => {
    conversation = new Conversation()
  })

  test('#validate validates body length', () => {
    expect(conversation.validate({body: ''})).toBeTruthy()
    expect(conversation.validate({body: null}).body).toBeTruthy()
    expect(
      conversation.validate({
        body: 'body',
        recipients: [{}],
      })
    ).toBeUndefined()
  })

  test('#validate validates there must be at least one recipient object', () => {
    const testData = {
      body: 'i love testing javascript',
      recipients: [{}],
    }

    expect(conversation.validate(testData)).toBeUndefined()

    testData.recipients = []
    expect(conversation.validate(testData).recipients).toBeTruthy()

    delete testData.recipients
    expect(conversation.validate(testData).recipients).toBeTruthy()
  })

  test('#url is the correct API url', () => {
    expect(conversation.url).toEqual('/api/v1/conversations')
  })
})

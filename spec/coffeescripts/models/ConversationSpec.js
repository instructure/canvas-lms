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

import Conversation from 'compiled/models/Conversation'

QUnit.module('Conversation', {
  setup() {
    this.conversation = new Conversation()
  }
})

test('#validate validates body length', function() {
  ok(this.conversation.validate({body: ''}))
  ok(this.conversation.validate({body: null}).body)
  ok(
    this.conversation.validate({
      body: 'body',
      recipients: [{}]
    }) === undefined
  )
})

test('#validate validates there must be at least one recipient object', function() {
  const testData = {
    body: 'i love testing javascript',
    recipients: [{}]
  }
  ok(this.conversation.validate(testData) === undefined)
  testData.recipients = []
  ok(this.conversation.validate(testData).recipients)
  delete testData.recipients
  ok(this.conversation.validate(testData).recipients)
})

test('#url is the correct API url', function() {
  equal(this.conversation.url, '/api/v1/conversations')
})

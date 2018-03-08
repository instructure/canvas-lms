/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import Reply from 'compiled/discussions/Reply'
import Entry from 'compiled/models/Entry'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import $ from 'jquery'

let sandbox

QUnit.module('Discussion Reply', {
  setup() {
    sandbox = sinon.sandbox.create()
  },
  teardown() {
    sandbox.restore()
  }
})

test('submit calls get_code on rce only once', () => {
  const $fake = $('<input>')
  const reply = Object.create(Reply.prototype)
  reply.form = $fake
  reply.discussionEntry = $fake
  reply.textArea = $fake
  reply.options = {}
  reply.view = {model: {set: () => {}, get: () => {}}}
  sandbox.stub(reply, 'trigger')
  sandbox.stub(Entry.prototype)
  reply.removeAttachments = () => {}
  const mock = sandbox.mock(RichContentEditor)
  mock
    .expects('callOnRCE')
    .once()
    .withExactArgs(reply.textArea, 'get_code')
  mock
    .expects('destroyRCE')
    .once()
    .withExactArgs(reply.textArea)
  reply.submit()
  mock.verify()
})

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

import MessageView from 'ui/features/conversations/backbone/views/MessageView'
import Message from 'ui/features/conversations/backbone/models/Message'

QUnit.module('MessageView', {
  setup() {
    this.model = new Message({
      subject: 'Hey There!',
      participants: [],
      last_message_at: Date.now(),
      last_authored_message_at: Date.now(),
    })
    this.view = new MessageView({model: this.model})
    this.view.render()
  },
  teardown() {
    this.view.remove()
  },
})

test('it sets proper SR text when starred with a subject', function () {
  this.model.set('starred', true)
  this.view.setStarBtnCheckedScreenReaderMessage()
  const actual = this.view.$el.find('.StarButton-LabelContainer').text()
  const expected = 'Starred "Hey There!", Click to unstar.'
  equal(actual, expected)
})

test('it sets proper SR text when starred without a subject', function () {
  this.model.set('starred', true)
  this.model.set('subject', null)
  this.view.setStarBtnCheckedScreenReaderMessage()
  const actual = this.view.$el.find('.StarButton-LabelContainer').text()
  const expected = 'Starred "(No Subject)", Click to unstar.'
  equal(actual, expected)
})

test('it sets proper SR text when unstarred without a subject', function () {
  this.model.set('starred', false)
  this.view.setStarBtnCheckedScreenReaderMessage()
  const actual = this.view.$el.find('.StarButton-LabelContainer').text()
  const expected = 'Not starred "Hey There!", Click to star.'
  equal(actual, expected)
})

test('it sets proper SR text when unstarred without a subject', function () {
  this.model.set('starred', false)
  this.model.set('subject', null)
  this.view.setStarBtnCheckedScreenReaderMessage()
  const actual = this.view.$el.find('.StarButton-LabelContainer').text()
  const expected = 'Not starred "(No Subject)", Click to star.'
  equal(actual, expected)
})

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

import MessageStudentsDialog from 'compiled/views/MessageStudentsDialog'
import $ from 'jquery'
import {pluck} from 'underscore'

QUnit.module('MessageStudentsDialog', {
  setup() {
    this.testData = {
      context: 'The Quiz',
      recipientGroups: [
        {
          name: 'have taken the quiz',
          recipients: [
            {
              id: 1,
              short_name: 'bob'
            }
          ]
        },
        {
          name: "haven't taken the quiz",
          recipients: [
            {
              id: 2,
              short_name: 'alice'
            }
          ]
        }
      ]
    }
    this.dialog = new MessageStudentsDialog(this.testData)
    this.dialog.render()
    $('#fixtures').append(this.dialog.$el)
  },
  teardown() {
    this.dialog.remove()
    $('#fixtures').empty()
  }
})

test('#initialize', function() {
  deepEqual(this.dialog.recipientGroups, this.testData.recipientGroups, 'saves recipientGroups')
  deepEqual(
    this.dialog.recipients,
    this.testData.recipientGroups[0].recipients,
    'saves first recipientGroups recipients to be displayed'
  )
  ok(this.dialog.options.title.match(this.testData.context), 'saves the title to be displayed')
  ok(this.dialog.model, 'creates conversation automatically')
})

test('updates list of recipients when dropdown changes', function() {
  this.dialog.$recipientGroupName.val("haven't taken the quiz").trigger('change')
  const html = this.dialog.$el.html()
  ok(html.match('alice'), 'updated with the new list of recipients')
  ok(!html.match('bob'), "doesn't contain old list of recipients")
})

test('#getFormValues returns correct values', function() {
  const messageBody = 'Students please take your quiz, dang it!'
  this.dialog.$messageBody.val(messageBody)
  const json = this.dialog.getFormData()
  const {body, recipients} = json
  strictEqual(json.body, messageBody, 'includes message body')
  strictEqual(json.recipientGroupName, undefined, "doesn't include recipientGroupName")
  deepEqual(
    json.recipients,
    pluck(this.testData.recipientGroups[0].recipients, 'id'),
    'includes list of ids'
  )
})

test('validateBeforeSave', function() {
  let errors = this.dialog.validateBeforeSave({body: ''}, {})
  ok(errors.body[0].message, 'validates empty body')
  errors = this.dialog.validateBeforeSave({body: 'take your dang quiz'}, {recipients: []})
  ok(errors.recipientGroupName[0].message, 'validates when sending to empty list of users')
})

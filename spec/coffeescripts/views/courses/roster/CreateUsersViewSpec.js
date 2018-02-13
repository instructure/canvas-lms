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

import $ from 'jquery'
import CreateUsersView from 'compiled/views/courses/roster/CreateUsersView'
import RolesCollection from 'compiled/collections/RolesCollection'
import Role from 'compiled/models/Role'
import CreateUserList from 'compiled/models/CreateUserList'
import assertions from 'helpers/assertions'

let view = null
let server = null

QUnit.module('CreateUsersView', {
  setup() {
    server = sinon.fakeServer.create()
    server.respondWith('POST', '/read', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify({
        users: [
          {
            address: 'joe@joe.com',
            name: null,
            type: 'email'
          }
        ],
        errored_users: [],
        duplicates: []
      })
    ])
    server.respondWith('POST', '/update', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify([
        {
          enrollment: {
            name: 'joe@joe.com',
            email: 'joe@joe.com',
            section: 'MWF'
          }
        }
      ])
    ])
    const roles = [
      {
        label: 'Teacher',
        name: 'TeacherEnrollment',
        manageable_by_user: true
      },
      {
        label: 'Student',
        name: 'StudentEnrollment',
        manageable_by_user: true
      },
      {
        label: 'Fake',
        name: 'Fake',
        manageable_by_user: false
      }
    ]
    view = new CreateUsersView({
      trigger: false,
      title: 'test',
      rolesCollection: new RolesCollection(roles.map(attributes => new Role(attributes))),
      model: new CreateUserList({
        sections: [
          {
            id: 1,
            name: 'MWF'
          },
          {
            id: 2,
            name: 'TTh'
          }
        ],
        roles,
        readURL: '/read',
        updateURL: '/update'
      })
    })
    $('#fixtures').append(view.$el)
    return view.open()
  },
  teardown() {
    server.restore()
    return view.remove()
  }
})
const addUserText = () => view.$textarea.val('joe@joe.com')
const goToStep2 = function() {
  $('#next-step').click()
  return server.respond()
}
const goToStep3 = function() {
  $('#createUsersAddButton').click()
  return server.respond()
}
const assertVerifiedUsers = () =>
  ok(
    $('#create-users-verified')
      .html()
      .match('joe@joe.com'),
    'verified users matched'
  )
const assertEnrolledUsers = () =>
  ok(
    $('#create-users-results')
      .html()
      .match('joe@joe.com'),
    'enrolled users matched'
  )
const assertStepVisible = step => assertions.isVisible($(`#create-users-step-${step}`))
const startOver = () => view.$('.createUsersStartOver').click()
const startOverFrd = () => view.$('.createUsersStartOverFrd').click()
const assertTextareaValue = text => equal(view.$textarea.val(), text, 'textarea matches text')

test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('moves through the steps', () => {
  assertStepVisible(1)
  addUserText()
  goToStep2()
  assertStepVisible(2)
  assertVerifiedUsers()
  goToStep3()
  assertStepVisible(3)
  assertEnrolledUsers()
  return view.close()
})

test('starts over on step 2', () => {
  addUserText()
  goToStep2()
  assertStepVisible(2)
  startOver()
  assertStepVisible(1)
  assertTextareaValue('joe@joe.com')
  return view.close()
})

test('starts over on step 3', () => {
  addUserText()
  goToStep2()
  goToStep3()
  assertStepVisible(3)
  startOverFrd()
  assertStepVisible(1)
  return assertTextareaValue('')
})

test('resets data on close and reopen', () => {
  addUserText()
  assertTextareaValue('joe@joe.com')
  view.close()
  view.open()
  return assertTextareaValue('')
})

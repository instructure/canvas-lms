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

import $ from 'jquery'

import RosterUserView from 'compiled/views/courses/roster/RosterUserView'
import RosterUser from 'compiled/models/RosterUser'

let rosterViewOne
let rosterViewTwo
let existingENV
let server

QUnit.module('RosterUserViewSpec', {
  setup() {
    window.ENV = window.ENV || {}
    existingENV = window.ENV
    window.ENV.permissions = {
      manage_admin_users: true,
      manage_students: true
    }
    window.ENV.course = {id: 1}

    rosterViewOne = new RosterUserView({
      model: new RosterUser({
        id: 1,
        enrollments: [
          {
            id: 1
          }
        ]
      })
    })

    rosterViewTwo = new RosterUserView({
      model: new RosterUser({
        id: 2,
        enrollments: [
          {
            id: 1
          }
        ]
      })
    })

    server = sinon.fakeServer.create()

    server.respondWith('POST', /unenroll/, [200, {'Content-Type': 'application/json'}, ''])

    $('#fixtures').append($('<button id="addUsers">'))

    sinon.stub(window, 'confirm').returns(true)
  },
  teardown() {
    rosterViewOne = null
    rosterViewTwo = null
    window.confirm.restore()
    window.ENV = existingENV
    server.restore()
    $('#fixtures').empty()
  }
})

test('moves focus to previous user when deleting a user in the middle', () => {
  const $listContainer = $('<div id="lists">')
  $listContainer.append(rosterViewOne.render().el)
  $listContainer.append(rosterViewTwo.render().el)
  $('#fixtures').append($listContainer)
  rosterViewTwo.removeFromCourse()
  server.respond()
  equal(document.activeElement, $('.al-trigger')[0], 'focus is set to the previous cog.')
})

test('moves focus to "+ People" button when deleting the top user', () => {
  const $listContainer = $('<div id="lists">')
  $listContainer.append(rosterViewOne.render().el)
  $listContainer.append(rosterViewTwo.render().el)
  $('#fixtures').append($listContainer)
  rosterViewOne.removeFromCourse()
  server.respond()
  equal(document.activeElement, $('#addUsers')[0], 'focus is set to + People button')
})

test('does not show sections when they are hidden by the hideSectionsOnCourseUsersPage setting', () => {
  ENV.course.hideSectionsOnCourseUsersPage = true
  $('#fixtures').append(rosterViewOne.render().el)
  const $cell = $('#fixtures').find('[data-test-id="section-column-cell"]')
  strictEqual($cell.length, 0)
})

test('shows sections when they are not hidden by the hideSectionsOnCourseUsersPage setting', () => {
  ENV.course.hideSectionsOnCourseUsersPage = false
  $('#fixtures').append(rosterViewOne.render().el)
  const $cell = $('#fixtures').find('[data-test-id="section-column-cell"]')
  strictEqual($cell.length, 1)
})

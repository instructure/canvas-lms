/* eslint-disable qunit/resolve-async */
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
import 'jquery-migrate'
import ProfileShow from 'ui/features/profile_show/backbone/views/ProfileShow'
import assertions from 'helpers/assertions'

QUnit.module('ProfileShow', {
  setup() {
    this.view = new ProfileShow()
    this.fixtures = document.getElementById('fixtures')
    this.fixtures.innerHTML = "<div class='.profile-link'></div>"
    this.fixtures.innerHTML += "<textarea id='profile_bio'></textarea>"
    this.fixtures.innerHTML +=
      "<table id='profile_link_fields'><input type='text' name='link_urls[]'></input></table>"
  },
  teardown() {
    this.fixtures.innerHTML = ''
  },
})

test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('manages focus on link removal', function () {
  this.view.addLinkField()
  const $row1 = $('#profile_link_fields tr:last-child')
  this.view.addLinkField()
  const $row2 = $('#profile_link_fields tr:last-child')
  this.view.removeLinkRow(null, $row2.find('.remove_link_row'))
  equal(document.activeElement, $row1.find('.remove_link_row')[0])
  this.view.removeLinkRow(null, $row1.find('.remove_link_row'))
  equal(document.activeElement, $('#profile_bio')[0])
})

test('focuses the name input when it is available and edit is clicked', function () {
  this.fixtures.innerHTML += "<input id='name_input' />"
  this.view.showEditForm()
  equal(document.activeElement, $('#name_input')[0])
})

test('focuses the bio text area when the name input is not available and edit is clicked', function () {
  this.view.showEditForm()
  equal(document.activeElement, $('#profile_bio')[0])
})

test('validates input length', function () {
  const oldInnerHTML = this.fixtures.innerHTML
  this.fixtures.innerHTML =
    "<form id='profile_form'><input id='profile_title' name='user_profile[title]'></input><textarea id='profile_bio' name='user_profile[bio]'></textarea></form>"

  // validates on good input
  $('#profile_title').val('a'.repeat(255))
  let event = {
    preventDefault: sinon.spy(),
    target: $('#profile_form'),
  }
  this.view.validateForm(event)
  ok(!event.preventDefault.called)

  // fails on bad input
  $('#profile_title').val('a'.repeat(256))
  event = {
    preventDefault: sinon.spy(),
    target: $('#profile_form'),
  }
  this.view.validateForm(event)
  ok(event.preventDefault.called)
  this.fixtures.innerHTML = oldInnerHTML
})

test('validates no spaces in URL', function () {
  const oldInnerHTML = this.fixtures.innerHTML
  this.fixtures.innerHTML =
    "<form id='profile_form'><table id='profile_link_fields'><input id='profile_link' type='text' name='link_urls[]'></input></table></form>"

  // validates on good input
  $('#profile_link').val('yahoo')
  let event = {
    preventDefault: sinon.spy(),
    target: $('#profile_form'),
  }
  this.view.validateForm(event)
  ok(!event.preventDefault.called)

  // fails on spaces
  $('#profile_link').val('ya hoo')
  event = {
    preventDefault: sinon.spy(),
    target: $('#profile_form'),
  }
  this.view.validateForm(event)
  ok(event.preventDefault.called)
  this.fixtures.innerHTML = oldInnerHTML
})

test('profile update successful text is shown when the success container is present', function () {
  const oldInnerHTML = this.fixtures.innerHTML
  this.fixtures.innerHTML = "<div id='profile_alert_holder_success'></div>"
  this.view = new ProfileShow()
  strictEqual(
    this.view.$('#profile_alert_holder_success').text(),
    'Profile has been saved successfully'
  )
  this.fixtures.innerHTML = oldInnerHTML
})

test('profile update failed text is shown when the failed container is present', function () {
  const oldInnerHTML = this.fixtures.innerHTML
  this.fixtures.innerHTML = "<div id='profile_alert_holder_failed'></div>"
  this.view = new ProfileShow()
  strictEqual(this.view.$('#profile_alert_holder_failed').text(), 'Profile save was unsuccessful')
  this.fixtures.innerHTML = oldInnerHTML
})

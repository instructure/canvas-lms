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
import ProfileShow from 'compiled/views/profiles/ProfileShow'
import assertions from 'helpers/assertions'

QUnit.module('ProfileShow', {
  setup() {
    this.view = new ProfileShow()
    this.fixtures = document.getElementById('fixtures')
    this.fixtures.innerHTML = "<div class='.profile-link'></div>"
    this.fixtures.innerHTML += "<textarea id='profile_bio'></textarea>"
    this.fixtures.innerHTML += "<table id='profile_link_fields'></table>"
  },
  teardown() {
    this.fixtures.innerHTML = ''
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.view, done, {a11yReport: true})
})

test('manages focus on link removal', function() {
  this.view.addLinkField()
  const $row1 = $('#profile_link_fields tr:last-child')
  this.view.addLinkField()
  const $row2 = $('#profile_link_fields tr:last-child')
  this.view.removeLinkRow(null, $row2.find('.remove_link_row'))
  equal(document.activeElement, $row1.find('.remove_link_row')[0])
  this.view.removeLinkRow(null, $row1.find('.remove_link_row'))
  equal(document.activeElement, $('#profile_bio')[0])
})

test('focuses the name input when it is available and edit is clicked', function() {
  this.fixtures.innerHTML += "<input id='name_input' />"
  this.view.showEditForm()
  equal(document.activeElement, $('#name_input')[0])
})

test('focuses the bio text area when the name input is not available and edit is clicked', function() {
  this.view.showEditForm()
  equal(document.activeElement, $('#profile_bio')[0])
})

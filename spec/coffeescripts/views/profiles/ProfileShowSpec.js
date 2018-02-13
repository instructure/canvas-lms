#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/views/profiles/ProfileShow'
  'helpers/assertions'
], ($, ProfileShow, assertions) ->

  QUnit.module 'ProfileShow',
    setup: ->
      @view = new ProfileShow
      @fixtures = document.getElementById('fixtures')
      @fixtures.innerHTML = "<div class='.profile-link'></div>"
      @fixtures.innerHTML += "<textarea id='profile_bio'></textarea>"
      @fixtures.innerHTML += "<table id='profile_link_fields'></table>"

    teardown: ->
      @fixtures.innerHTML = ""

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @view, done, {'a11yReport': true}

  test 'manages focus on link removal', ->
    @view.addLinkField()
    $row1 = $('#profile_link_fields tr:last-child')
    @view.addLinkField()
    $row2 = $('#profile_link_fields tr:last-child')

    @view.removeLinkRow(null, $row2.find('.remove_link_row'))
    equal document.activeElement, $row1.find('.remove_link_row')[0]
    @view.removeLinkRow(null, $row1.find('.remove_link_row'))
    equal document.activeElement, $('#profile_bio')[0]

  test 'focuses the name input when it is available and edit is clicked', ->
    @fixtures.innerHTML += "<input id='name_input' />"
    @view.showEditForm()
    equal(document.activeElement, $('#name_input')[0])

  test 'focuses the bio text area when the name input is not available and edit is clicked', ->
    @view.showEditForm()
    equal(document.activeElement, $('#profile_bio')[0])

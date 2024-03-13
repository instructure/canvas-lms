/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {addUsersLink, openReportDescriptionLink} from 'ui/features/account_settings/jquery/index'

QUnit.module('AccountSettings.openReportDescriptionLink', {
  setup() {
    const $html = $('<div>')
      .addClass('title')
      .addClass('reports')
      .append($('<span>').addClass('title').text('Title'))
      .append($('<div>').addClass('report_description').text('Description'))
      .append($('<a>').addClass('trigger'))
    $html.find('a').click(openReportDescriptionLink)
    $('#fixtures').append($html)
  },
  teardown() {
    $('#fixtures').empty()
    $('.ui-dialog').remove()
  },
})

test('keeps the description in the DOM', () => {
  $('#fixtures .trigger').click()
  ok($('#fixtures .report_description').length)
})

QUnit.module('AccountSettings.addUsersLink', {
  setup() {
    const $select = $('<select>').attr('id', 'admin_role_id').append($('<option>').attr('val', '1'))
    const $form = $('<div>').attr('id', 'enroll_users_form').append($select)
    const $trigger = $('<a>').addClass('trigger').click(addUsersLink)
    $('#fixtures').append($form)
    $('#fixtures').append($trigger)
    $form.hide()
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('keeps the description in the DOM', () => {
  $('#fixtures .trigger').click()
  equal(document.activeElement, $('#admin_role_id')[0])
})

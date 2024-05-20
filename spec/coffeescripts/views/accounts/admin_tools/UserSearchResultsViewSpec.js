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
import 'jquery-migrate'
import UserSearchResultsView from 'ui/features/account_admin_tools/backbone/views/UserSearchResultsView'
import UserRestore from 'ui/features/account_admin_tools/backbone/models/UserRestore'
import {initFlashContainer} from '@canvas/rails-flash-notifications'

const errorMessageJSON = {
  status: 'not_found',
  message: 'There was no foo bar in the baz',
}

const userJSON = {
  id: 17,
  name: 'Deleted User',
  sis_user_id: null,
}

QUnit.module('UserSearchResultsView', {
  setup() {
    this.userRestore = new UserRestore({account_id: 6})
    this.userSearchResultsView = new UserSearchResultsView({model: this.userRestore})
    $('#fixtures').append($('<div id="flash_screenreader_holder" />'))
    return $('#fixtures').append(this.userSearchResultsView.render().el)
  },
  teardown() {
    $('#fixtures').empty()
  },
})

test('restored is set to false when initialized', function () {
  ok(!this.userRestore.get('restored'))
})

test('render is called whenever the model has a change event triggered', function () {
  sandbox.mock(this.userSearchResultsView).expects('render').once()
  this.userSearchResultsView.applyBindings()
  return this.userRestore.trigger('change')
})

test('pressing the restore button calls restore on the model and view', function () {
  this.userRestore.set(userJSON)
  sandbox.mock(this.userRestore).expects('restore').once().returns($.Deferred().resolve())
  return this.userSearchResultsView.$restoreUserBtn.click()
})

test('not found message is displayed when model has no id and a status', function () {
  this.userRestore.clear({silent: true})
  this.userRestore.set(errorMessageJSON)
  ok(this.userSearchResultsView.$el.find('.alert-error').length > 0, 'Error message is displayed')
})

test('options to restore a user and its details should be displayed when a deleted user is found', function () {
  this.userRestore.set(userJSON)
  ok(
    this.userSearchResultsView.$el.find('#restoreUserBtn').length > 0,
    'Restore user button displayed'
  )
})

test('show screenreader text when user not found', function () {
  initFlashContainer()
  this.userRestore.clear({silent: true})
  this.userRestore.set(errorMessageJSON)
  this.userSearchResultsView.resultsFound()
  ok($('#flash_screenreader_holder').text().match('User not found'))
})

test('show screenreader text on finding deleted user', function () {
  initFlashContainer()
  this.userRestore.set(userJSON)
  this.userSearchResultsView.resultsFound()
  ok($('#flash_screenreader_holder').text().match('User found'))
})

test('show screenreader text on finding non-deleted user', function () {
  initFlashContainer()
  this.userRestore.set({
    ...userJSON,
    login_id: 'du',
  })
  this.userSearchResultsView.resultsFound()
  ok(
    $('#flash_screenreader_holder')
      .text()
      .match(/User found \(not deleted\)/)
  )
})

test('shows options to view a user if a user was restored', function () {
  this.userRestore.set(userJSON, {silent: true})
  this.userRestore.set('restored', true, {silent: true})
  this.userRestore.set('login_id', 'du')
  ok(this.userSearchResultsView.$el.find('.alert-success').length > 0, 'User restore displayed')
  ok(this.userSearchResultsView.$el.find('#viewUser').length > 0, 'Viewing a user displayed')
})

test('shows options to view a user', function () {
  this.userRestore.set(userJSON, {silent: true})
  this.userRestore.set('login_id', 'du')
  ok(this.userSearchResultsView.$el.find('#viewUser').length > 0, 'Viewing a user displayed')
})

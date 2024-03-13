/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import usersTemplate from 'ui/features/account_admin_tools/jst/usersList.handlebars'
import CommMessageCollection from 'ui/features/account_admin_tools/backbone/collections/CommMessageCollection'
import AccountUserCollection from 'ui/features/account_admin_tools/backbone/collections/AccountUserCollection'
import UserDateRangeSearchFormView from 'ui/features/account_admin_tools/backbone/views/UserDateRangeSearchFormView'
import InputFilterView from '@canvas/backbone-input-filter-view'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import UserView from 'ui/features/account_admin_tools/backbone/views/UserView'

QUnit.module('UserDateRangeSearchFormView', {
  setup() {
    const messages = new CommMessageCollection(null, {params: {perPage: 10}})
    const messagesUsers = new AccountUserCollection(null, {account_id: 1})
    this.searchForm = new UserDateRangeSearchFormView({
      formName: 'messages',
      inputFilterView: new InputFilterView({collection: messagesUsers}),
      usersView: new PaginatedCollectionView({
        collection: messagesUsers,
        itemView: UserView,
        buffer: 1000,
        template: usersTemplate,
      }),
      collection: messages,
    })
    $('#fixtures').append(this.searchForm.render().el)
  },

  teardown() {
    this.searchForm.remove()
  },

  changeDate(startDate, endDate) {
    this.searchForm.$dateStartSearchField.val(startDate)
    this.searchForm.$dateEndSearchField.val(endDate)
    this.searchForm.$dateStartSearchField.trigger('change')
    this.searchForm.$dateEndSearchField.trigger('change')
  },
})

test('find with no dates is valid', function () {
  this.changeDate('', '')
  const errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 0)
})

test('find with one date selected is valid', function () {
  this.changeDate('Jan 16, 2018', '')
  let errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 0)

  this.changeDate('', 'Jan 16, 2018')
  errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 0)
})

test('find with start date before end date is valid', function () {
  this.changeDate('Jan 04, 2018', 'Jan 12, 2018')
  const errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 0)
})

test('find with invalid dates is invalid', function () {
  this.changeDate('', 'banana')
  let errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 1)
  strictEqual(errors.messages_end_time[0].message, 'Not a valid date')

  this.changeDate('banana', 'Jan 16, 2018')
  errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 1)
  strictEqual(errors.messages_start_time[0].message, 'Not a valid date')

  this.changeDate('banana', 'banana')
  errors = this.searchForm.datesValidation()
  // The previous end date was valid and is stored so there is no error
  strictEqual(Object.keys(errors).length, 1)
  strictEqual(errors.messages_start_time[0].message, 'Not a valid date')
})

test('find with start date after end date is invalid', function () {
  this.changeDate('Jan 12, 2018', 'Jan 1, 2018')
  const errors = this.searchForm.datesValidation()
  strictEqual(Object.keys(errors).length, 1)
  strictEqual(errors.messages_end_time[0].message, 'To Date cannot come before From Date')
})

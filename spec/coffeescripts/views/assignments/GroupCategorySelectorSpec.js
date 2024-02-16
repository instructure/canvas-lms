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

import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import StudentGroupStore from '@canvas/due-dates/react/StudentGroupStore'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'

/* eslint-disable object-shorthand */
QUnit.module('GroupCategorySelector selection', {
  beforeEach: function () {
    this.assignment = new Assignment()
    this.assignment.groupCategoryId('1')
    this.groupCategories = [
      {
        id: '1',
        name: 'GS1',
      },
      {
        id: '2',
        name: 'GS2',
      },
    ]
    this.groupCategorySelector = new GroupCategorySelector({
      parentModel: this.assignment,
      groupCategories: this.groupCategories,
    })
    this.groupCategorySelector.render()
    return $('#fixtures').append(this.groupCategorySelector.$el)
  },
  afterEach: function () {
    this.groupCategorySelector.remove()
    $('#fixtures').empty()
  },
})

QUnit.test("groupCategorySelected should set StudentGroupStore's group set", function () {
  strictEqual(StudentGroupStore.getSelectedGroupSetId(), '1')
  this.groupCategorySelector.$groupCategoryID.val(2)
  this.groupCategorySelector.groupCategorySelected()
  strictEqual(StudentGroupStore.getSelectedGroupSetId(), '2')
})

QUnit.test('New Group Category button is enabled when can manage groups', () => {
  strictEqual($('#create_group_category_id:disabled').length, 0)
})

QUnit.module('GroupCategorySelector, no groups', {
  beforeEach: function () {
    fakeENV.setup()
    ENV.PERMISSIONS = {can_manage_groups: false}
    this.assignment = new Assignment()
    this.groupCategorySelector = new GroupCategorySelector({
      parentModel: this.assignment,
      groupCategories: [],
    })
    this.groupCategorySelector.render()
    return $('#fixtures').append(this.groupCategorySelector.$el)
  },
  afterEach: function () {
    fakeENV.teardown()
    this.groupCategorySelector.remove()
    $('#fixtures').empty()
  },
})

QUnit.test('group category select is hidden when there are no group sets', () => {
  const $group_category = $('#fixtures #assignment_group_category')
  strictEqual($group_category.css('display'), 'none')
})

QUnit.test('New Group Category button is disabled when cannot manage groups', () => {
  strictEqual($('#create_group_category_id:disabled').length, 1)
})
/* eslint-enable object-shorthand */

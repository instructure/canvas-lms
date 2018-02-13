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

import GroupCategorySelector from 'compiled/views/assignments/GroupCategorySelector'
import Assignment from 'compiled/models/Assignment'
import StudentGroupStore from 'jsx/due_dates/StudentGroupStore'
import $ from 'jquery'

QUnit.module('GroupCategorySelector', {
  setup() {
    this.assignment = new Assignment()
    this.assignment.groupCategoryId('1')
    this.groupCategories = [
      {
        id: '1',
        name: 'GS1'
      },
      {
        id: '2',
        name: 'GS2'
      }
    ]
    this.groupCategorySelector = new GroupCategorySelector({
      parentModel: this.assignment,
      groupCategories: this.groupCategories
    })
    this.groupCategorySelector.render()
    return $('#fixtures').append(this.groupCategorySelector.$el)
  },
  teardown() {
    this.groupCategorySelector.remove()
    $('#fixtures').empty()
  }
})

test("groupCategorySelected should set StudentGroupStore's group set", function() {
  strictEqual(StudentGroupStore.getSelectedGroupSetId(), '1')
  this.groupCategorySelector.$groupCategoryID.val(2)
  this.groupCategorySelector.groupCategorySelected()
  strictEqual(StudentGroupStore.getSelectedGroupSetId(), '2')
})

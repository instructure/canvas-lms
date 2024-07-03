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

import GroupCategorySelector from '../GroupCategorySelector'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import StudentGroupStore from '@canvas/due-dates/react/StudentGroupStore'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const strictEqual = (x, y) => expect(x).toStrictEqual(y)

let assignment
let groupCategories
let groupCategorySelector

describe('GroupCategorySelector selection', () => {
  beforeEach(() => {
    assignment = new Assignment()
    assignment.groupCategoryId('1')
    groupCategories = [
      {
        id: '1',
        name: 'GS1',
      },
      {
        id: '2',
        name: 'GS2',
      },
    ]
    groupCategorySelector = new GroupCategorySelector({
      parentModel: assignment,
      groupCategories,
    })
    groupCategorySelector.render()
    return $('#fixtures').append(groupCategorySelector.$el)
  })

  afterEach(() => {
    groupCategorySelector.remove()
    $('#fixtures').empty()
  })

  test("groupCategorySelected should set StudentGroupStore's group set", function () {
    strictEqual(StudentGroupStore.getSelectedGroupSetId(), '1')
    groupCategorySelector.$groupCategoryID.val(2)
    groupCategorySelector.groupCategorySelected()
    strictEqual(StudentGroupStore.getSelectedGroupSetId(), '2')
  })

  test('New Group Category button is enabled when can manage groups', () => {
    strictEqual($('#create_group_category_id:disabled').length, 0)
  })

  describe('GroupCategorySelector, no groups', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.PERMISSIONS = {can_manage_groups: false}
      assignment = new Assignment()
      groupCategorySelector = new GroupCategorySelector({
        parentModel: assignment,
        groupCategories: [],
      })
      groupCategorySelector.render()
      return $('#fixtures').append(groupCategorySelector.$el)
    })

    afterEach(() => {
      fakeENV.teardown()
      groupCategorySelector.remove()
      $('#fixtures').empty()
    })

    // :disabled psuedoselector doesn't work in Jest
    test.skip('group category select is hidden when there are no group sets', () => {
      const $group_category = $('#fixtures #assignment_group_category')
      strictEqual($group_category.css('display'), 'none')
    })

    // :disabled psuedoselector doesn't work in Jest
    test.skip('New Group Category button is disabled when cannot manage groups', () => {
      strictEqual($('#create_group_category_id:disabled').length, 1)
    })
  })
})

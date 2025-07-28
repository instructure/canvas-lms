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

import GroupCategorySelector, {GROUP_CATEGORY_SELECT} from '../GroupCategorySelector'
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
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })
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
    fakeENV.setup({PERMISSIONS: {can_manage_groups: true}})
    assignment.canGroup = () => true
    groupCategorySelector.render()
    expect($('#create_group_category_id').prop('disabled')).toBe(false)
  })

  it('returns an error if no group was selected', () => {
    const errors = groupCategorySelector.validateBeforeSave({group_category_id: 'blank'}, {})
    expect(errors).toEqual({
      [GROUP_CATEGORY_SELECT]: [{message: 'Please select a group set for this assignment'}],
    })
  })

  describe('GroupCategorySelector, no groups', () => {
    beforeEach(() => {
      ENV.PERMISSIONS = {can_manage_groups: false}
      assignment = new Assignment()
      groupCategorySelector = new GroupCategorySelector({
        parentModel: assignment,
        groupCategories: [],
        showNewErrors: true,
      })
      groupCategorySelector.render()
      return $('#fixtures').append(groupCategorySelector.$el)
    })

    afterEach(() => {
      groupCategorySelector.remove()
      $('#fixtures').empty()
    })

    it('returns an error if no group set was created', () => {
      fakeENV.setup({PERMISSIONS: {can_manage_groups: true}})
      const errors = groupCategorySelector.validateBeforeSave({group_category_id: 'blank'}, {})
      expect(errors).toEqual({[GROUP_CATEGORY_SELECT]: [{message: 'Please create a group set'}]})
    })

    it('returns an error if user does not have create group permissions', () => {
      const errors = groupCategorySelector.validateBeforeSave({group_category_id: 'blank'}, {})
      expect(errors).toEqual({
        [GROUP_CATEGORY_SELECT]: [
          {message: 'Group Add permission is needed to create a New Group Category'},
        ],
      })
    })
  })

  describe('GroupCategorySelector disabled state', () => {
    beforeEach(() => {
      fakeENV.setup({PERMISSIONS: {can_manage_groups: false}})
      assignment = new Assignment()
      assignment.canGroup = () => false
      assignment.frozenAttributes = () => ['group_category_id']
      groupCategorySelector = new GroupCategorySelector({
        parentModel: assignment,
        groupCategories,
        inClosedGradingPeriod: true,
      })
      groupCategorySelector.render()
      return $('#fixtures').append(groupCategorySelector.$el)
    })

    afterEach(() => {
      fakeENV.teardown()
      groupCategorySelector.remove()
      $('#fixtures').empty()
    })

    it('disables the group category dropdown when groupCategoryLocked is true', () => {
      expect(groupCategorySelector.$groupCategoryID.prop('disabled')).toBe(true)
    })

    // fickle
    it.skip('disables the create new group category button when groupCategoryLocked is true', () => {
      expect($('#create_group_category_id').prop('disabled')).toBe(true)
    })
  })

  describe('GroupCategorySelector switching groups', () => {
    beforeEach(() => {
      assignment = new Assignment()
      assignment.canGroup = () => true
      assignment.groupCategoryId('1')
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
      StudentGroupStore.setSelectedGroupSet(null)
    })

    it('updates group category selection when switching between groups', () => {
      expect(groupCategorySelector.$groupCategoryID.val()).toBe('1')
      expect(StudentGroupStore.getSelectedGroupSetId()).toBe('1')

      groupCategorySelector.$groupCategoryID.val('2')
      groupCategorySelector.groupCategorySelected()
      expect(groupCategorySelector.$groupCategoryID.val()).toBe('2')
      expect(StudentGroupStore.getSelectedGroupSetId()).toBe('2')
    })

    it('resets group category selection when component is removed', () => {
      expect(StudentGroupStore.getSelectedGroupSetId()).toBe('1')
      groupCategorySelector.remove()
      StudentGroupStore.setSelectedGroupSet(null)
      expect(StudentGroupStore.getSelectedGroupSetId()).toBe(null)
    })
  })
})

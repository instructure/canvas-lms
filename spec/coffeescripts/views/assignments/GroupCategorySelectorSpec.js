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
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/models/Assignment'
  'jsx/due_dates/StudentGroupStore'
  'jquery'
], (GroupCategorySelector, Assignment, StudentGroupStore, $) ->

  QUnit.module "GroupCategorySelector",
    setup: ->
      @assignment = new Assignment
      @assignment.groupCategoryId("1")
      @groupCategories = [
        {id: "1", name: 'GS1'},
        {id: "2", name: 'GS2'}]
      @groupCategorySelector =
        new GroupCategorySelector parentModel: @assignment, groupCategories: @groupCategories
      @groupCategorySelector.render()
      $('#fixtures').append @groupCategorySelector.$el

    teardown: ->
      @groupCategorySelector.remove()
      $('#fixtures').empty()

  test "groupCategorySelected should set StudentGroupStore's group set", ->
    strictEqual StudentGroupStore.getSelectedGroupSetId(), "1"
    @groupCategorySelector.$groupCategoryID.val(2)
    @groupCategorySelector.groupCategorySelected()
    strictEqual StudentGroupStore.getSelectedGroupSetId(), "2"


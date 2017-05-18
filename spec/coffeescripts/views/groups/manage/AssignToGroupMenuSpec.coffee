#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'compiled/views/groups/manage/AssignToGroupMenu'
  'compiled/collections/GroupCollection'
  'compiled/models/Group'
  'compiled/models/GroupUser'
  'compiled/models/GroupCategory'
], ($, AssignToGroupMenu, GroupCollection, Group, GroupUser, GroupCategory) ->

  view = null
  user = null

  QUnit.module 'AssignToGroupMenu',
    setup: ->
      groupCategory = new GroupCategory
      user = new GroupUser(id: 1, name: "bob", group: null, category: groupCategory)
      groups = new GroupCollection [
        new Group id: 1, name: "a group"
      ], {category: groupCategory}
      view = new AssignToGroupMenu
        collection: groups
        model: user
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test "updates the user's group", ->
    equal user.get('group'), null
    $link = view.$('.set-group')
    equal $link.length, 1
    $link.click()
    equal user.get('group').id, 1

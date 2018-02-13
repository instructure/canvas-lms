#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'compiled/models/GroupCategory'
  'compiled/views/groups/manage/GroupCategoryCreateView'
  'helpers/fakeENV'
], ($, GroupCategory, GroupCategoryCreateView, fakeENV) ->

  view = null
  groupCategory = null

  QUnit.module 'GroupCategoryCreateView',
    setup: ->
      fakeENV.setup({allow_self_signup: true})
      groupCategory = new GroupCategory()
      view = new GroupCategoryCreateView({model: groupCategory})
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'toggling auto group leader enables and disables accompanying controls', ->
    $(".auto-group-leader-toggle").click()

    view.$autoGroupLeaderControls.find('label.radio').each ->
      equal $(this).css('opacity'), "1"
    $(".auto-group-leader-toggle").click()

    view.$autoGroupLeaderControls.find('label.radio').each ->
      equal $(this).css('opacity'), "0.5"

  test 'auto group leader controls are hidden if we arent splitting groups automatically', ->
    view.$autoGroupSplitControl.prop("checked", true)
    view.$autoGroupSplitControl.trigger('click')
    ok(view.$autoGroupLeaderControls.is(":visible"))
    view.$autoGroupSplitControl.prop("checked", false)
    view.$autoGroupSplitControl.trigger('click')
    ok(view.$autoGroupLeaderControls.is(":hidden"))

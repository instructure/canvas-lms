/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import GroupCategory from 'compiled/models/GroupCategory'
import GroupCategoryCreateView from 'compiled/views/groups/manage/GroupCategoryCreateView'
import fakeENV from 'helpers/fakeENV'

let view = null
let groupCategory = null

QUnit.module('GroupCategoryCreateView', {
  setup() {
    fakeENV.setup({allow_self_signup: true})
    groupCategory = new GroupCategory()
    view = new GroupCategoryCreateView({model: groupCategory})
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    fakeENV.teardown()
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  }
})

QUnit.skip('toggling auto group leader enables and disables accompanying controls', function() {
  $('.auto-group-leader-toggle').click()
  view.$autoGroupLeaderControls.find('label.radio').each(function() {
    equal($(this).css('opacity'), '1', 'opacity is 1')
  })
  $('.auto-group-leader-toggle').click()
  view.$autoGroupLeaderControls.find('label.radio').each(function() {
    equal($(this).css('opacity'), '0.5', 'opacity is .5')
  })
})

test('auto group leader controls are hidden if we arent splitting groups automatically', () => {
  view.$autoGroupSplitControl.prop('checked', true)
  view.$autoGroupSplitControl.trigger('click')
  ok(view.$autoGroupLeaderControls.is(':visible'))
  view.$autoGroupSplitControl.prop('checked', false)
  view.$autoGroupSplitControl.trigger('click')
  ok(view.$autoGroupLeaderControls.is(':hidden'))
})

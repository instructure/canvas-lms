/* eslint-disable qunit/resolve-async */
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
import 'jquery-migrate'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import GroupCategoryEditView from '@canvas/groups/backbone/views/GroupCategoryEditView'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

let view = null
let groupCategory = null

QUnit.module('GroupCategoryEditView', {
  setup() {
    fakeENV.setup({allow_self_signup: true})
    groupCategory = new GroupCategory()
    view = new GroupCategoryEditView({model: groupCategory})
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    fakeENV.teardown()
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  },
})

test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('auto leadership is unset without model state', () => {
  groupCategory.set('auto_leader', null)
  view.setAutoLeadershipFormState()
  equal(view.$autoGroupLeaderToggle.prop('checked'), false)
})

test('auto leadership corresponds to model state', () => {
  groupCategory.set('auto_leader', 'random')
  view.setAutoLeadershipFormState()
  equal(view.$autoGroupLeaderToggle.prop('checked'), true)
  equal(view.$autoGroupLeaderControls.find("input[value='RANDOM']").prop('checked'), true)
  equal(view.$autoGroupLeaderControls.find("input[value='FIRST']").prop('checked'), false)
})

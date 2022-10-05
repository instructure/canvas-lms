/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import AssignToGroupMenu from 'ui/features/manage_groups/backbone/views/AssignToGroupMenu'
import GroupCollection from '@canvas/groups/backbone/collections/GroupCollection.coffee'
import Group from '@canvas/groups/backbone/models/Group.coffee'
import GroupUser from '@canvas/groups/backbone/models/GroupUser.coffee'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory.coffee'
import assertions from 'helpers/assertions'

let view = null
let user = null

QUnit.module('AssignToGroupMenu', {
  setup() {
    const groupCategory = new GroupCategory()
    user = new GroupUser({
      id: 1,
      name: 'bob',
      group: null,
      category: groupCategory,
    })
    const groups = new GroupCollection(
      [
        new Group({
          id: 1,
          name: 'a group',
        }),
      ],
      {category: groupCategory}
    )
    view = new AssignToGroupMenu({
      collection: groups,
      model: user,
    })
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  },
})

test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test("updates the user's group", () => {
  equal(user.get('group'), null)
  const $link = view.$('.set-group')
  equal($link.length, 1)
  $link.click()
  equal(user.get('group').id, 1)
})

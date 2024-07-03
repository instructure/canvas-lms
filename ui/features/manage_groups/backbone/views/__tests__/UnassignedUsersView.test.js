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
import UnassignedUsersView from '../UnassignedUsersView'
import AssignToGroupMenu from '../AssignToGroupMenu'
import GroupCollection from '@canvas/groups/backbone/collections/GroupCollection'
import UnassignedGroupUserCollection from '@canvas/groups/backbone/collections/UnassignedGroupUserCollection'
import Group from '@canvas/groups/backbone/models/Group'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import sinon from 'sinon'

const equal = (x, y) => expect(x).toBe(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let clock = null
let view = null
let groups = null
let users = null

describe('UnassignedUsersView', () => {
  beforeEach(() => {
    fakeENV.setup()
    $('#fixtures').html('<div id="content"></div>')
    clock = sinon.useFakeTimers()
    groups = new GroupCollection([new Group({name: 'a group'}), new Group({name: 'another group'})])
    users = new UnassignedGroupUserCollection(
      [
        {id: 1, name: 'bob', sortable_name: 'bob'},
        {id: 2, name: 'joe', sortable_name: 'joe'},
      ],
      {category: new GroupCategory()}
    )
    const menu = new AssignToGroupMenu({collection: groups})
    view = new UnassignedUsersView({
      collection: users,
      groupsCollection: groups,
      assignToGroupMenu: menu,
    })
    view.render()
    $('#fixtures')
      .append(view.$el)
      .append($('<div />', {id: 'content'}))
  })

  afterEach(() => {
    fakeENV.teardown()
    $('#fixtures').empty()
    clock.restore()
    view.remove()
    $('#fixtures').empty()
  })

  // :visible doesn't work in Jest
  test.skip('opens the assignToGroupMenu', () => {
    view.$('.assign-to-group').eq(0).simulate('click')
    clock.tick(100)
    const $menu = $('.assign-to-group-menu').filter(':visible')
    equal($menu.length, 1)
    equal($menu.find('.set-group').length, 2)
  })
})

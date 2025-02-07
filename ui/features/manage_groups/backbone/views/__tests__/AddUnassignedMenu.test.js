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

import GroupUserCollection from '@canvas/groups/backbone/collections/GroupUserCollection'
import GroupUser from '@canvas/groups/backbone/models/GroupUser'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import Group from '@canvas/groups/backbone/models/Group'
import AddUnassignedMenu from '../AddUnassignedMenu'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import {waitFor} from '@testing-library/react'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

let clock = null
let server = null
let waldo = null
let users = null
let view = null
const sendResponse = (method, url, json) => {
  server.respond.mockImplementationOnce((method, url, response) => {
    if (response[1]['Content-Type'] === 'application/json') {
      return JSON.parse(response[2])
    }
    return response[2]
  })(method, url, [200, {'Content-Type': 'application/json'}, JSON.stringify(json)])
}

describe('AddUnassignedMenu', () => {
  beforeEach(() => {
    fakeENV.setup()
    clock = jest.useFakeTimers()
    server = {
      respond: jest.fn().mockImplementation((method, url, response) => {
        return Promise.resolve({
          status: response[0],
          headers: response[1],
          json: () => Promise.resolve(JSON.parse(response[2])),
        })
      }),
      restore: jest.fn(),
    }
    waldo = new GroupUser({
      id: 4,
      name: 'Waldo',
      sortable_name: 'Waldo',
    })
    users = new GroupUserCollection(null, {
      group: new Group(),
      category: new GroupCategory(),
    })
    users.setParam('search_term', 'term')
    users.loaded = true
    view = new AddUnassignedMenu({collection: users})
    view.group = new Group({id: 777})
    users.reset([
      new GroupUser({
        id: 1,
        name: 'Frank Herbert',
        sortable_name: 'Herbert, Frank',
      }),
      new GroupUser({
        id: 2,
        name: 'Neal Stephenson',
        sortable_name: 'Stephenson, Neal',
      }),
      new GroupUser({
        id: 3,
        name: 'John Scalzi',
        sortable_name: 'Scalzi, John',
      }),
      waldo,
    ])
    view.$el.appendTo($('#fixtures'))
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.useRealTimers()
    server.restore.mockClear()
    view.remove()
    document.getElementById('fixtures').innerHTML = ''
  })

  test("updates the user's group and removes from unassigned collection", () => {
    equal(waldo.get('group'), undefined)
    const $links = view.$('.assign-user-to-group')
    equal($links.length, 4)
    const $waldoLink = $links.last()
    $waldoLink.click()
    sendResponse('POST', '/api/v1/groups/777/memberships', {})
    equal(waldo.get('group'), view.group)
    ok(!users.contains(waldo))
  })

  test('does not hide immediately on outerclick after opening', async () => {
    // Create a dummy content element with id "content" so that position() doesn't fail.
    const $dummyContent = $(
      '<div id="content" style="position: relative; top: 0; height: 500px;"></div>',
    ).appendTo('#fixtures')
    const $dummyTarget = $('<div></div>').appendTo('#fixtures')

    // Open the popover.
    view.showBy($dummyTarget)

    // Wait for the menu to render
    await waitFor(() => {
      expect(document.body.contains(view.el)).toBe(true)
    })

    // Trigger an outerclick event as soon as it renders.
    view.$el.triggerHandler('outerclick', [document.createElement('div')])

    // Verify that the menu didn't close
    expect(document.body.contains(view.el)).toBe(true)

    $dummyTarget.remove()
    $dummyContent.remove()
  })
})

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

// @ts-expect-error - Legacy Backbone typing
const ok = x => expect(x).toBeTruthy()
// @ts-expect-error - Legacy Backbone typing
const equal = (x, y) => expect(x).toEqual(y)

let clock = null
// @ts-expect-error - Legacy Backbone typing
let server = null
// @ts-expect-error - Legacy Backbone typing
let waldo = null
// @ts-expect-error - Legacy Backbone typing
let users = null
// @ts-expect-error - Legacy Backbone typing
let view = null
// @ts-expect-error - Legacy Backbone typing
const sendResponse = (method, url, json) => {
  // @ts-expect-error - Legacy Backbone typing
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
    clock = vi.useFakeTimers()
    server = {
      respond: vi.fn().mockImplementation((method, url, response) => {
        return Promise.resolve({
          status: response[0],
          headers: response[1],
          json: () => Promise.resolve(JSON.parse(response[2])),
        })
      }),
      restore: vi.fn(),
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
    // @ts-expect-error - Backbone View property
    users.setParam('search_term', 'term')
    users.loaded = true
    // @ts-expect-error - Legacy Backbone typing
    view = new AddUnassignedMenu({collection: users})
    // @ts-expect-error - Backbone View property
    view.group = new Group({id: 777})
    // @ts-expect-error - Backbone View property
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
    // @ts-expect-error - Backbone View property
    view.$el.appendTo($('#fixtures'))
  })

  afterEach(() => {
    fakeENV.teardown()
    vi.useRealTimers()
    // @ts-expect-error - Legacy Backbone typing
    server.restore.mockClear()
    // @ts-expect-error - Legacy Backbone typing
    view.remove()
    // @ts-expect-error - Legacy Backbone typing
    document.getElementById('fixtures').innerHTML = ''
  })

  test("updates the user's group and removes from unassigned collection", () => {
    // @ts-expect-error - Legacy Backbone typing
    equal(waldo.get('group'), undefined)
    // @ts-expect-error - Legacy Backbone typing
    const $links = view.$('.assign-user-to-group')
    equal($links.length, 4)
    const $waldoLink = $links.last()
    $waldoLink.click()
    sendResponse('POST', '/api/v1/groups/777/memberships', {})
    // @ts-expect-error - Legacy Backbone typing
    equal(waldo.get('group'), view.group)
    // @ts-expect-error - Legacy Backbone typing
    ok(!users.contains(waldo))
  })

  test('does not hide immediately on outerclick after opening', async () => {
    // Create a dummy content element with id "content" so that position() doesn't fail.
    const $dummyContent = $(
      '<div id="content" style="position: relative; top: 0; height: 500px;"></div>',
    ).appendTo('#fixtures')
    const $dummyTarget = $('<div></div>').appendTo('#fixtures')

    // Open the popover.
    // @ts-expect-error - Legacy Backbone typing
    view.showBy($dummyTarget)

    // Wait for the menu to render
    await waitFor(() => {
      // @ts-expect-error - Legacy Backbone typing
      expect(document.body.contains(view.el)).toBe(true)
    })

    // Trigger an outerclick event as soon as it renders.
    // @ts-expect-error - Legacy Backbone typing
    view.$el.triggerHandler('outerclick', [document.createElement('div')])

    // Verify that the menu didn't close
    // @ts-expect-error - Legacy Backbone typing
    expect(document.body.contains(view.el)).toBe(true)

    $dummyTarget.remove()
    $dummyContent.remove()
  })
})

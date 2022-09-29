/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {reorderElements, backbone} from '@canvas/move-item-tray'

const container = document.getElementById('fixtures')

QUnit.module('MoveItem utils', {
  teardown: () => {
    container.innerHTML = ''
  },
})

test('reorderElements puts elements in correct order', () => {
  container.innerHTML = `
    <div id="id4"></div>
    <div id="id1"></div>
    <div id="id3"></div>
    <div id="id2"></div>
  `
  const desiredOrder = ['id1', 'id2', 'id3', 'id4']
  reorderElements(desiredOrder, container)

  const newOrder = Array.prototype.map.call(container.children, node => node.getAttribute('id'))
  deepEqual(desiredOrder, newOrder)
})

test('reorderElements ignores non-existent elements', () => {
  container.innerHTML = `
    <div id="id2"></div>
    <div id="id1"></div>
  `
  reorderElements(['id1', 'id3', 'id2'], container)
  const newOrder = Array.prototype.map.call(container.children, node => node.getAttribute('id'))
  deepEqual(['id1', 'id2'], newOrder)
})

test('backbone.collectionToItems parses collection correctly', () => {
  const coll = {
    models: [
      {attributes: {id: '4', name: 'foo', thing: 'fizz'}},
      {attributes: {id: '6', title: 'bar', beep: 'boop'}},
      {attributes: {id: '8', name: 'buzz'}},
    ],
  }

  const result = backbone.collectionToItems(coll)
  const desired = [
    {id: '4', title: 'foo'},
    {id: '6', title: 'bar'},
    {id: '8', title: 'buzz'},
  ]

  deepEqual(result, desired)
})

test('backbone.collectionToGroups parses collection correctly', () => {
  const coll = {
    models: [
      {
        attributes: {
          id: '4',
          name: 'foo',
          users: {
            models: [
              {attributes: {id: '4', name: 'foo', thing: 'fizz'}},
              {attributes: {id: '6', title: 'bar', beep: 'boop'}},
            ],
          },
        },
      },
      {
        attributes: {
          id: '6',
          title: 'bar',
          users: {
            models: [
              {attributes: {id: '4', name: 'foo', thing: 'fizz'}},
              {attributes: {id: '6', title: 'bar', beep: 'boop'}},
            ],
          },
        },
      },
    ],
  }

  const result = backbone.collectionToGroups(coll, col => col.attributes.users)
  const desired = [
    {
      id: '4',
      title: 'foo',
      items: [
        {id: '4', title: 'foo'},
        {id: '6', title: 'bar'},
      ],
    },
    {
      id: '6',
      title: 'bar',
      items: [
        {id: '4', title: 'foo'},
        {id: '6', title: 'bar'},
      ],
    },
  ]

  deepEqual(result, desired)
})

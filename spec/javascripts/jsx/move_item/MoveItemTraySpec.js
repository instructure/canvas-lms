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

import React from 'react'
import * as enzyme from 'enzyme'
import MoveItemTray from '@canvas/move-item-tray/react/index'

QUnit.module('MoveItemTray component')

const defaultProps = () => ({
  title: 'Move Item',
  items: [
    {
      id: '10',
      title: 'Foo Bar',
    },
  ],
  moveOptions: {
    siblings: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  },
  focusOnExit: () => {},
  formatSaveUrl: () => {},
  onMoveSuccess: () => {},
  onExited: () => {},
  applicationElement: () => document.getElementById('fixtures'),
})

test('renders the MoveItemTray component', () => {
  const tree = enzyme.mount(<MoveItemTray {...defaultProps()} />)
  ok(tree.exists())
})

test('renders one MoveSelect component on initial open', () => {
  const tree = enzyme.shallow(<MoveItemTray {...defaultProps()} />)
  const node = tree.find('MoveSelect')
  equal(node.length, 1)
})

test('open sets the state.open to true', () => {
  const tree = enzyme.mount(<MoveItemTray {...defaultProps()} />)
  const instance = tree.instance()
  instance.open()
  ok(instance.state.open)
})

test('close sets the state.open to false', () => {
  const tree = enzyme.mount(<MoveItemTray {...defaultProps()} />)
  const instance = tree.instance()
  instance.close()
  notOk(instance.state.open)
})

test('closing the tray calls onExited', () => {
  const props = defaultProps()
  props.onExited = sinon.spy()
  const tree = enzyme.mount(<MoveItemTray {...props} />)
  const instance = tree.instance()
  const clock = sinon.useFakeTimers()
  instance.close()
  clock.tick(500)
  ok(props.onExited.calledOnce)
  clock.restore()
})

test('onMoveSelect calls onMoveSuccess with move data', () => {
  const props = defaultProps()
  props.onMoveSuccess = sinon.spy()
  const tree = enzyme.mount(<MoveItemTray {...props} />)
  const instance = tree.instance()
  const clock = sinon.useFakeTimers()
  instance.onMoveSelect({order: ['1', '2', '3'], groupId: '5', itemIds: ['2']})
  clock.tick(500)
  ok(props.onMoveSuccess.calledWith, {data: ['1', '2', '3'], groupId: '5', itemIda: ['2']})
  clock.restore()
})

test('calls onFocus on the result of focusOnExit on close', () => {
  const focusItem = {focus: sinon.spy()}
  const props = defaultProps()
  props.focusOnExit = () => focusItem
  const tree = enzyme.mount(<MoveItemTray {...props} />)
  const instance = tree.instance()
  const clock = sinon.useFakeTimers()
  instance.close()
  clock.tick(500)
  ok(focusItem.focus.calledOnce)
  clock.restore()
})

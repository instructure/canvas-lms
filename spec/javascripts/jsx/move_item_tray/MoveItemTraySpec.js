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
import MoveItemTray from 'jsx/move_item_tray/MoveItemTray'
import Select from 'instructure-ui/lib/components/Select'

QUnit.module('MoveItemTray component')

const defaultProps = () => ({
  title: "Move Item Tray",
  currentItem: { // The chosen item to be inserted into the main list
    id: "10",
    title: "item",
  },
  moveSelectionList: [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ], // Array of all the elements except the current item
  open: true, // Determine the state of the moving item tray at start
  onExited: () => {},
  onMoveTraySubmit: () => {}
})

test('renders the MoveItemTray component', () => {
  const tree = enzyme.shallow(<MoveItemTray {...defaultProps()} />)
  const node = tree.find('.move-item-tray')
  ok(node.exists())
})

test('renders one Select component on initial open', () => {
  const tree = enzyme.shallow(<MoveItemTray {...defaultProps()} />)
  const node = tree.find(Select)
  equal(node.length, 1);
})

test('renders two Select component on after state', () => {
  const wrapper = enzyme.shallow(<MoveItemTray {...defaultProps()} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'after'
    }
  })
  const node = wrapper.find(Select)
  equal(node.length, 2);
})

test('renders two Select component on before state', () => {
  const wrapper = enzyme.shallow(<MoveItemTray {...defaultProps()} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'before'
    }
  })
  const node = wrapper.find(Select)
  equal(node.length, 2);
})

test('calls onMoveTraySubmit for setting place to top', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'first'
    }
  })
  ok(spy.calledOnce);
})

test('calls onMoveTraySubmit for setting place to bottom', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'last'
    }
  })
  ok(spy.calledOnce);
})

test('does not call onMoveTraySubmit for other values', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'before'
    }
  })
  ok(!spy.calledOnce);
})

test('does not call if value is not in list', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.currentItem = { // The chosen item to be inserted into the main list
    id: "10",
    title: "item",
  }
  props.moveSelectionList = [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ]
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().setState({ currentAction: 'before'})
  wrapper.instance().onChangeRelativeMove({
    target : {
      value : "15"
    }
  })
  ok(!spy.called)
})

test('calls onMoveTraySubmit correctly for placing before', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.currentItem = { // The chosen item to be inserted into the main list
    id: "10",
    title: "item",
  }
  props.moveSelectionList = [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ]
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().setState({ currentAction: 'before'})
  wrapper.instance().onChangeRelativeMove({
    target : {
      value : "12"
    }
  })
  ok(spy.calledWith(["10", "12", "30", "55"]))
})

test('calls onMoveTraySubmit correctly for placing after', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.currentItem = { // The chosen item to be inserted into the main list
    id: "10",
    title: "item",
  }
  props.moveSelectionList = [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ]
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().setState({ currentAction: 'after'})
  wrapper.instance().onChangeRelativeMove({
    target : {
      value : "12"
    }
  })
  ok(spy.calledWith(["12", "10", "30", "55"]))
})

test('correctly for calls item with first spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.currentItem = { // The chosen item to be inserted into the main list
    id: "123",
    title: "item",
  }
  props.moveSelectionList = [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ]
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'first'
    }
  })
  ok(spy.calledWith(["123", "12", "30", "55"]))
})

test('correctly for calls item in last spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.currentItem = { // The chosen item to be inserted into the main list
    id: "10",
    title: "item",
  }
  props.moveSelectionList = [
    { attributes: {id: "12"} },
    { attributes: {id: "30"} },
    { attributes: {id: "55"} }
  ]
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<MoveItemTray {...props} />)
  wrapper.instance().onChangePlacement({
    target : {
      value : 'last'
    }
  })
  ok(spy.calledWith(["12", "30", "55", "10"]))
})

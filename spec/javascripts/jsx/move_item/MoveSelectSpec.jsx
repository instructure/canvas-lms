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
import MoveSelect from '@canvas/move-item-tray/react/MoveSelect'
import {positions} from '@canvas/positions'

QUnit.module('MoveSelect component')

const defaultProps = () => ({
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
  onSelect: () => {},
})

test('renders the MoveSelect component', () => {
  const tree = enzyme.mount(<MoveSelect {...defaultProps()} />)
  ok(tree.exists())
})

test('hasSelectedPosition() is false if selectedPosition is false-y', () => {
  const tree = enzyme.mount(<MoveSelect {...defaultProps()} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: null})
  notOk(instance.hasSelectedPosition())
})

test('hasSelectedPosition() is true if selectedPosition is an absolute position', () => {
  const tree = enzyme.mount(<MoveSelect {...defaultProps()} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.last})
  ok(instance.hasSelectedPosition())
})

test('hasSelectedPosition() is false if selectedPosition is a relative position and selectedSibling is false-y', () => {
  const tree = enzyme.mount(<MoveSelect {...defaultProps()} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.before, selectedSibling: null})
  notOk(instance.hasSelectedPosition())
})

test('hasSelectedPosition() is true if selectedPosition is a relative position and selectedSibling is valid', () => {
  const tree = enzyme.mount(<MoveSelect {...defaultProps()} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.before, selectedSibling: '2'})
  ok(instance.hasSelectedPosition())
})

test('isDoneSelecting() is true if props.moveOptions is siblings and hasSelectedPosition() is true', () => {
  const props = defaultProps()
  props.moveOptions = {
    siblings: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.last})
  ok(instance.isDoneSelecting())
})

test('isDoneSelecting() is true if props.moveOptions is siblings because of default position', () => {
  const props = defaultProps()
  props.moveOptions = {
    siblings: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.before})
  ok(instance.isDoneSelecting())
})

test('isDoneSelecting() is false if props.moveOptions is groups and selectedGroup is false-y', () => {
  const props = defaultProps()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedGroup: null})
  notOk(instance.isDoneSelecting())
})

test('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid with items because of default position', () => {
  const props = defaultProps()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {id: '12', title: 'Making Cake', items: [{id: '2', title: 'foo bar'}]},
      {id: '30', title: 'Very Hard Quiz', items: [{id: '4', title: 'foo baz'}]},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({
    selectedGroup: props.moveOptions.groups[0],
    selectedPosition: positions.before,
  })
  ok(instance.isDoneSelecting())
})

test('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid with items but hasSelectedPosition() is true', () => {
  const props = defaultProps()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {id: '12', title: 'Making Cake', items: [{id: '2', title: 'foo bar'}]},
      {id: '30', title: 'Very Hard Quiz', items: [{id: '4', title: 'foo baz'}]},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedGroup: props.moveOptions.groups[0], selectedPosition: positions.first})
  ok(instance.isDoneSelecting())
})

test('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid without items', () => {
  const props = defaultProps()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedGroup: props.moveOptions.groups[0]})
  ok(instance.isDoneSelecting())
})

test('submitSelection() calls onSelect with properly ordered items for siblings', () => {
  const props = defaultProps()
  props.onSelect = sinon.spy()
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({selectedPosition: positions.before, selectedSibling: 1})
  instance.submitSelection()
  ok(props.onSelect.calledWith({groupId: null, order: ['12', '10', '30'], itemIds: ['10']}))
})

test('submitSelection() calls onSelect with properly ordered items for groups', () => {
  const props = defaultProps()
  props.onSelect = sinon.spy()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {
        id: '12',
        title: 'Making Cake',
        items: [
          {id: '2', title: 'foo bar'},
          {id: '8', title: 'baz foo'},
        ],
      },
      {
        id: '30',
        title: 'Very Hard Quiz',
        items: [
          {id: '4', title: 'foo baz'},
          {id: '6', title: 'bar foo'},
        ],
      },
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({
    selectedPosition: positions.before,
    selectedGroup: props.moveOptions.groups[0],
    selectedSibling: 1,
  })
  instance.submitSelection()
  ok(props.onSelect.calledWith({groupId: '12', order: ['2', '10', '8'], itemIds: ['10']}))
})

test('submitSelection() calls onSelect with properly ordered items for multple items', () => {
  const props = defaultProps()
  props.items = [
    {
      id: '88',
      title: 'Bleh Bar',
      groupId: '12',
    },
    {
      id: '14',
      title: 'Blerp Bar',
    },
    {
      id: '12',
      title: 'Blop Bar',
    },
  ]
  props.onSelect = sinon.spy()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {
        id: '12',
        title: 'Making Cake',
        items: [
          {id: '2', title: 'foo bar'},
          {id: '8', title: 'baz foo'},
        ],
      },
      {
        id: '30',
        title: 'Very Hard Quiz',
        items: [
          {id: '4', title: 'foo baz'},
          {id: '6', title: 'bar foo'},
        ],
      },
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({
    selectedPosition: positions.before,
    selectedGroup: props.moveOptions.groups[1],
    selectedSibling: 1,
  })
  instance.submitSelection()
  ok(
    props.onSelect.calledWith({
      groupId: '30',
      order: ['4', '88', '14', '12', '6'],
      itemIds: ['88', '14', '12'],
    })
  )
})

test('submitSelection() calls onSelect with properly ordered items for multple items for an absolute position', () => {
  const props = defaultProps()
  props.items = [
    {
      id: '88',
      title: 'Bleh Bar',
      groupId: '12',
    },
    {
      id: '14',
      title: 'Blerp Bar',
    },
    {
      id: '12',
      title: 'Blop Bar',
    },
  ]
  props.onSelect = sinon.spy()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {
        id: '12',
        title: 'Making Cake',
        items: [
          {id: '2', title: 'foo bar'},
          {id: '8', title: 'baz foo'},
        ],
      },
      {
        id: '30',
        title: 'Very Hard Quiz',
        items: [
          {id: '4', title: 'foo baz'},
          {id: '6', title: 'bar foo'},
        ],
      },
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({
    selectedPosition: positions.last,
    selectedGroup: props.moveOptions.groups[1],
    selectedSibling: 1,
  })
  instance.submitSelection()
  ok(
    props.onSelect.calledWith({
      groupId: '30',
      order: ['4', '6', '88', '14', '12'],
      itemIds: ['88', '14', '12'],
    })
  )
})

test('submitSelection() calls onSelect with properly ordered items for a selected group in the first position', () => {
  const props = defaultProps()
  props.items = [
    {
      id: '88',
      title: 'Bleh Bar',
      groupId: '12',
    },
    {
      id: '14',
      title: 'Blerp Bar',
    },
    {
      id: '12',
      title: 'Blop Bar',
    },
  ]
  props.onSelect = sinon.spy()
  props.moveOptions = {
    groupsLabel: 'groups',
    groups: [
      {
        id: '12',
        title: 'Making Cake',
        items: [
          {id: '2', title: 'foo bar'},
          {id: '8', title: 'baz foo'},
        ],
      },
      {
        id: '30',
        title: 'Very Hard Quiz',
        items: [
          {id: '4', title: 'foo baz'},
          {id: '6', title: 'bar foo'},
        ],
      },
    ],
  }
  const tree = enzyme.mount(<MoveSelect {...props} />)
  const instance = tree.instance()
  instance.setState({
    selectedPosition: positions.first,
    selectedGroup: props.moveOptions.groups[0],
    selectedSibling: 0,
  })
  instance.submitSelection()
  ok(
    props.onSelect.calledWith({
      groupId: '12',
      order: ['88', '14', '12', '2', '8'],
      itemIds: ['88', '14', '12'],
    })
  )
})

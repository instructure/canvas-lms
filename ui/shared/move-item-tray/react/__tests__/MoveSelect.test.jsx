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
import {positions} from '@canvas/positions'
import {render, screen} from '@testing-library/react'
import MoveSelect from '../MoveSelect'

const stubs = {
  onSelect: jest.fn(),
  onClose: jest.fn(),
}
const defaultProps = (props = {}) => ({
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
  onSelect: stubs.onSelect,
  onClose: stubs.onClose,
  ...props,
})
const renderMoveSelect = (props = {}) => {
  const ref = React.createRef()
  const wrapper = render(<MoveSelect {...defaultProps(props)} ref={ref} />)

  return {
    ref,
    ...wrapper,
  }
}
const setupRefForMultipleItems = () => {
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
  return {
    ...renderMoveSelect(props),
    props,
  }
}

describe('MoveSelect', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the MoveSelect component', () => {
    renderMoveSelect()

    expect(screen.getByText('Move')).toBeInTheDocument()
  })

  it('hasSelectedPosition() is false if selectedPosition is false-y', () => {
    const {ref} = renderMoveSelect()

    ref.current.setState({selectedPosition: null})

    expect(ref.current.hasSelectedPosition()).toBe(false)
  })

  it('hasSelectedPosition() is true if selectedPosition is an absolute position', () => {
    const {ref} = renderMoveSelect()

    ref.current.setState({selectedPosition: positions.last})

    expect(ref.current.hasSelectedPosition()).toBe(true)
  })

  it('hasSelectedPosition() is false if selectedPosition is a relative position and selectedSibling is false-y', () => {
    const {ref} = renderMoveSelect()

    ref.current.setState({selectedPosition: positions.before, selectedSibling: null})

    expect(ref.current.hasSelectedPosition()).toBe(false)
  })

  it('hasSelectedPosition() is true if selectedPosition is a relative position and selectedSibling is valid', () => {
    const {ref} = renderMoveSelect()

    ref.current.setState({selectedPosition: positions.before, selectedSibling: '2'})

    expect(ref.current.hasSelectedPosition()).toBe(true)
  })

  it('isDoneSelecting() is true if props.moveOptions is siblings and hasSelectedPosition() is true', () => {
    const props = defaultProps()
    props.moveOptions = {
      siblings: [
        {id: '12', title: 'Making Cake'},
        {id: '30', title: 'Very Hard Quiz'},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({selectedPosition: positions.last})

    expect(ref.current.isDoneSelecting()).toBe(true)
  })

  it('isDoneSelecting() is true if props.moveOptions is siblings because of default position', () => {
    const props = defaultProps()
    props.moveOptions = {
      siblings: [
        {id: '12', title: 'Making Cake'},
        {id: '30', title: 'Very Hard Quiz'},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({selectedPosition: positions.before})

    expect(ref.current.isDoneSelecting()).toBe(true)
  })

  it('isDoneSelecting() is false if props.moveOptions is groups and selectedGroup is false-y', () => {
    const props = defaultProps()
    props.moveOptions = {
      groupsLabel: 'groups',
      groups: [
        {id: '12', title: 'Making Cake'},
        {id: '30', title: 'Very Hard Quiz'},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({selectedGroup: null})

    expect(ref.current.isDoneSelecting()).toBe(false)
  })

  it('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid with items because of default position', () => {
    const props = defaultProps()
    props.moveOptions = {
      groupsLabel: 'groups',
      groups: [
        {id: '12', title: 'Making Cake', items: [{id: '2', title: 'foo bar'}]},
        {id: '30', title: 'Very Hard Quiz', items: [{id: '4', title: 'foo baz'}]},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({
      selectedGroup: props.moveOptions.groups[0],
      selectedPosition: positions.before,
    })

    expect(ref.current.isDoneSelecting()).toBe(true)
  })

  it('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid with items but hasSelectedPosition() is true', () => {
    const props = defaultProps()
    props.moveOptions = {
      groupsLabel: 'groups',
      groups: [
        {id: '12', title: 'Making Cake', items: [{id: '2', title: 'foo bar'}]},
        {id: '30', title: 'Very Hard Quiz', items: [{id: '4', title: 'foo baz'}]},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({
      selectedGroup: props.moveOptions.groups[0],
      selectedPosition: positions.first,
    })

    expect(ref.current.isDoneSelecting()).toBe(true)
  })

  it('isDoneSelecting() is true if props.moveOptions is groups and selectedGroup is valid without items', () => {
    const props = defaultProps()
    props.moveOptions = {
      groupsLabel: 'groups',
      groups: [
        {id: '12', title: 'Making Cake'},
        {id: '30', title: 'Very Hard Quiz'},
      ],
    }
    const {ref} = renderMoveSelect(props)

    ref.current.setState({selectedGroup: props.moveOptions.groups[0]})

    expect(ref.current.isDoneSelecting()).toBe(true)
  })

  it('submitSelection() calls onSelect with properly ordered items for siblings', () => {
    const {ref} = renderMoveSelect()

    ref.current.setState({selectedPosition: positions.before, selectedSibling: 1})
    ref.current.submitSelection()

    expect(stubs.onSelect).toHaveBeenCalledWith({
      groupId: null,
      order: ['12', '10', '30'],
      itemIds: ['10'],
    })
  })

  it('submitSelection() calls onSelect with properly ordered items for groups', () => {
    const props = defaultProps()
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
    const {ref} = renderMoveSelect(props)

    ref.current.setState({
      selectedPosition: positions.before,
      selectedGroup: props.moveOptions.groups[0],
      selectedSibling: 1,
    })
    ref.current.submitSelection()

    expect(stubs.onSelect).toHaveBeenCalledWith({
      groupId: '12',
      order: ['2', '10', '8'],
      itemIds: ['10'],
    })
  })

  it('submitSelection() calls onSelect with properly ordered items for multple items', () => {
    const {ref, props} = setupRefForMultipleItems()

    ref.current.setState({
      selectedPosition: positions.before,
      selectedGroup: props.moveOptions.groups[1],
      selectedSibling: 1,
    })
    ref.current.submitSelection()

    expect(stubs.onSelect).toHaveBeenCalledWith({
      groupId: '30',
      order: ['4', '88', '14', '12', '6'],
      itemIds: ['88', '14', '12'],
    })
  })

  it('submitSelection() calls onSelect with properly ordered items for multple items for an absolute position', () => {
    const {ref, props} = setupRefForMultipleItems()

    ref.current.setState({
      selectedPosition: positions.last,
      selectedGroup: props.moveOptions.groups[1],
      selectedSibling: 1,
    })
    ref.current.submitSelection()

    expect(stubs.onSelect).toHaveBeenCalledWith({
      groupId: '30',
      order: ['4', '6', '88', '14', '12'],
      itemIds: ['88', '14', '12'],
    })
  })

  it('submitSelection() calls onSelect with properly ordered items for a selected group in the first position', () => {
    const {ref, props} = setupRefForMultipleItems()

    ref.current.setState({
      selectedPosition: positions.first,
      selectedGroup: props.moveOptions.groups[0],
      selectedSibling: 0,
    })
    ref.current.submitSelection()

    expect(stubs.onSelect).toHaveBeenCalledWith({
      groupId: '12',
      order: ['88', '14', '12', '2', '8'],
      itemIds: ['88', '14', '12'],
    })
  })
})

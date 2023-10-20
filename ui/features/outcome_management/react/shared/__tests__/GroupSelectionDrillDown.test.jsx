/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import GroupSelectionDrillDown from '../GroupSelectionDrillDown'

describe('GroupSelectionDrillDown', () => {
  let mockOnCollectionClick

  const defaultProps = (props = {}) => ({
    collections: {
      1: {
        id: '1',
        name: 'Root Group',
        collections: ['2', '3'],
        parentGroupId: 0,
      },
      2: {
        id: '2',
        name: 'Group 2',
        collections: ['4'],
        parentGroupId: '1',
      },
      3: {
        id: '3',
        name: 'Group 3',
        collections: ['4'],
        parentGroupId: '1',
      },
      4: {
        id: '4',
        name: 'Group 4',
        collections: [],
        parentGroupId: '3',
      },
      5: {
        id: '5',
        name: 'Group Without Parent',
        collections: [],
        parentGroupId: '999',
      },
    },
    rootId: '0',
    selectedGroupId: '1',
    loadedGroups: ['1'],
    onCollectionClick: mockOnCollectionClick,
    ...props,
  })

  beforeEach(() => {
    mockOnCollectionClick = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component with root group as selected group', () => {
    const props = defaultProps()
    const {getByText} = render(<GroupSelectionDrillDown {...props} />)
    expect(getByText(props.collections[1].name)).toBeInTheDocument()
  })

  it('renders only subgroups of selected group', () => {
    const props = defaultProps()
    const {getByText, queryByText} = render(<GroupSelectionDrillDown {...props} />)
    expect(getByText(props.collections[2].name)).toBeInTheDocument()
    expect(getByText(props.collections[3].name)).toBeInTheDocument()
    expect(queryByText(props.collections[4].name)).not.toBeInTheDocument()
  })

  it('calls onCollectionClick when an option is clicked', () => {
    const props = defaultProps()
    const {getByText} = render(<GroupSelectionDrillDown {...props} />)
    fireEvent.click(getByText(props.collections[2].name))
    expect(mockOnCollectionClick).toHaveBeenCalled()
  })

  it('does not render the group that is being moved', () => {
    const {name, id} = defaultProps().collections[2]
    const {queryByText} = render(<GroupSelectionDrillDown {...defaultProps({movingGroupId: id})} />)
    expect(queryByText(name)).not.toBeInTheDocument()
  })

  it('calls onCollectionClick properly when back button is clicked and the parent group isnt in the collections', () => {
    const props = defaultProps({selectedGroupId: '5'})
    const {getByText} = render(<GroupSelectionDrillDown {...props} />)
    fireEvent.click(getByText('Back'))
    expect(mockOnCollectionClick).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        id: '999',
      })
    )
  })

  it('works with passing selectedGroupId that is not in the collections', () => {
    const props = defaultProps({selectedGroupId: '123'})
    const {getByText} = render(<GroupSelectionDrillDown {...props} />)
    expect(getByText('Loading')).toBeInTheDocument()
  })
})

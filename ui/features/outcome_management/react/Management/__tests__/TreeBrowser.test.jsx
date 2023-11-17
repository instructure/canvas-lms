// @vitest-environment jsdom
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
import {render, fireEvent, act} from '@testing-library/react'
import TreeBrowser from '../TreeBrowser'

jest.useFakeTimers()

describe('TreeBrowser', () => {
  let onCollectionToggle, collections, onCreateGroup

  const defaultProps = (props = {}) => ({
    collections,
    rootId: '1',
    onCollectionToggle,
    showRootCollection: true,
    defaultExpandedIds: ['1'],
    onCreateGroup,
    loadedGroups: ['1'],
    ...props,
  })

  beforeEach(() => {
    collections = {
      1: {
        id: '1',
        name: 'Root account folder',
        descriptor: '2 Groups | 2 Outcomes',
        collections: ['100', '101'],
        outcomesCount: 2,
        childGroupsCount: 2,
        parentGroupId: '0',
        loadInfo: 'loaded',
      },
      100: {
        id: '100',
        name: 'Folder with groups',
        descriptor: '2 Groups | 2 Outcomes',
        collections: [],
        outcomesCount: 2,
        childGroupsCount: 2,
        parentGroupId: '1',
      },
      101: {
        id: '101',
        name: 'Leaf folder',
        descriptor: '0 Groups | 2 Outcomes',
        collections: [],
        outcomesCount: 2,
        childGroupsCount: 0,
        parentGroupId: '1',
      },
    }
    onCollectionToggle = jest.fn()
    onCreateGroup = jest.fn()

    ENV = {
      current_user: {
        fake_student: undefined,
      },
      current_user_is_student: false,
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders root and leaf collections', () => {
    const {getByText} = render(<TreeBrowser {...defaultProps()} />)
    expect(getByText('Root account folder')).toBeInTheDocument()
    expect(getByText('Folder with groups')).toBeInTheDocument()
    expect(getByText('Leaf folder')).toBeInTheDocument()
  })

  describe('create group item', () => {
    it('does not render when the group is not expanded', () => {
      const {queryByText} = render(<TreeBrowser {...defaultProps({defaultExpandedIds: []})} />)
      expect(queryByText('Create New Group')).not.toBeInTheDocument()
    })

    it('does not render when is a student', () => {
      ENV.current_user_is_student = true
      const {queryByText} = render(<TreeBrowser {...defaultProps({loadedGroups: ['1']})} />)
      expect(queryByText('Create New Group')).not.toBeInTheDocument()
    })

    it('does not render when is a fake student', () => {
      ENV.current_user.fake_student = true
      const {queryByText} = render(<TreeBrowser {...defaultProps({loadedGroups: ['1']})} />)
      expect(queryByText('Create New Group')).not.toBeInTheDocument()
    })

    it('does not render an item for each expanded group when is a student', () => {
      ENV.current_user_is_student = true
      const {queryAllByText} = render(
        <TreeBrowser
          {...defaultProps({defaultExpandedIds: ['1', '100'], loadedGroups: ['1', '100']})}
        />
      )
      expect(queryAllByText('Create New Group')).toHaveLength(0)
    })

    it('does not render an item for each expanded group when is a fake student', () => {
      ENV.current_user.fake_student = true
      const {queryAllByText} = render(
        <TreeBrowser
          {...defaultProps({defaultExpandedIds: ['1', '100'], loadedGroups: ['1', '100']})}
        />
      )
      expect(queryAllByText('Create New Group')).toHaveLength(0)
    })

    it('does not render when the group is not loaded', () => {
      const {queryByText} = render(<TreeBrowser {...defaultProps({loadedGroups: []})} />)
      expect(queryByText('Create New Group')).not.toBeInTheDocument()
    })

    it('renders when the group is expanded and loaded', () => {
      const {getByText} = render(<TreeBrowser {...defaultProps()} />)
      expect(getByText('Create New Group')).toBeInTheDocument()
    })

    it('expands and focuses on text box when clicked', async () => {
      const {getByText, getByLabelText} = render(<TreeBrowser {...defaultProps()} />)
      fireEvent.click(getByText('Create New Group'))
      await act(async () => jest.runAllTimers())
      expect(getByLabelText('Enter new group name')).toHaveFocus()
    })

    it('calls onCreateGroup when a group is saved', () => {
      const {getByText, getByLabelText} = render(<TreeBrowser {...defaultProps()} />)
      fireEvent.click(getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group name'},
      })
      fireEvent.click(getByText('Create new group'))
      expect(onCreateGroup).toHaveBeenCalled()
    })

    it('renders an item for each expanded group', () => {
      const {getAllByText} = render(
        <TreeBrowser
          {...defaultProps({defaultExpandedIds: ['1', '100'], loadedGroups: ['1', '100']})}
        />
      )
      expect(getAllByText('Create New Group')).toHaveLength(2)
    })

    it('only expands a max of one item at a time', () => {
      const {getAllByText, getByText} = render(
        <TreeBrowser
          {...defaultProps({defaultExpandedIds: ['1', '100'], loadedGroups: ['1', '100']})}
        />
      )
      // expand one, then expand the other
      fireEvent.click(getAllByText('Create New Group')[0])
      expect(getAllByText('Create New Group')).toHaveLength(1)
      fireEvent.click(getByText('Create New Group'))
      expect(getAllByText('Create New Group')).toHaveLength(1)
    })

    it('unexpands the item anytime a collection is clicked', () => {
      const {getByText, getByLabelText, queryByLabelText} = render(
        <TreeBrowser {...defaultProps()} />
      )
      fireEvent.click(getByText('Create New Group'))
      expect(getByLabelText('Enter new group name')).toBeInTheDocument()
      fireEvent.click(getByText('Folder with groups'))
      expect(queryByLabelText('Enter new group name')).not.toBeInTheDocument()
    })
  })

  it('calls onCollectionToggle when a collection is clicked', () => {
    const {getByText} = render(<TreeBrowser {...defaultProps()} />)
    fireEvent.click(getByText('Leaf folder'))
    expect(onCollectionToggle).toHaveBeenCalledWith(expect.objectContaining({id: '101'}))
  })

  it('Sort collections by name', () => {
    collections = {
      ...collections,
      1: {
        ...collections[1],
        collections: ['100', '101', '102'],
      },
      102: {
        id: '102',
        name: 'Art group',
        descriptor: '0 Groups | 2 Outcomes',
        collections: [],
        outcomesCount: 0,
        childGroupsCount: 0,
        parentGroupId: '1',
      },
    }
    const {baseElement} = render(<TreeBrowser {...defaultProps()} />)
    const values = [].map.call(baseElement.querySelectorAll('button'), el => el.textContent)

    expect(values).toStrictEqual([
      // Note, the first group is Root account",
      // because this is the parent. The children are sorted properly
      'Root account folder2 Groups | 2 Outcomes',
      'Art group0 Groups | 2 Outcomes',
      'Folder with groups2 Groups | 2 Outcomes',
      'Leaf folder0 Groups | 2 Outcomes',
    ])
  })
})

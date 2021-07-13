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
import GroupActionDrillDown from '../GroupActionDrillDown'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.useFakeTimers()

describe('GroupActionDrillDown', () => {
  let onCollectionClick, showFlashAlertSpy

  const collections = {
    0: {
      id: '0',
      name: 'Root folder',
      collections: ['1', '2'],
      parentGroupId: null
    },
    1: {
      id: '1',
      name: 'Account folder',
      collections: ['100', '101'],
      outcomesCount: 2,
      parentGroupId: '0'
    },
    2: {
      id: '2',
      name: 'State folder',
      collections: [],
      outcomesCount: 2,
      childGroupsCount: 2,
      parentGroupId: '0'
    },
    100: {
      id: '100',
      name: 'Folder with groups',
      collections: ['101'],
      outcomesCount: 0,
      parentGroupId: '1'
    },
    101: {
      id: '101',
      name: 'Leaf folder',
      collections: [],
      outcomesCount: 1,
      parentGroupId: '1'
    }
  }

  const defaultProps = (props = {}) => ({
    collections,
    rootId: '0',
    onCollectionClick,
    loadedGroups: ['0', '1', '2', '100', '101'],
    ...props
  })

  beforeEach(() => {
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    onCollectionClick = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('initially renders the children of the root group', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
    fireEvent.click(getByText('Groups'))
    expect(getByText('Account folder')).toBeInTheDocument()
    expect(getByText('State folder')).toBeInTheDocument()
  })

  it("renders a back option to navigate to the selected group's parent", () => {
    const {getByText, queryByText} = render(<GroupActionDrillDown {...defaultProps()} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    expect(queryByText('State folder')).not.toBeInTheDocument()
    fireEvent.click(getByText('Back'))
    expect(getByText('State folder')).toBeInTheDocument()
  })

  it('shows a flash alert with the parent group name after clicking the back button', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    fireEvent.click(getByText('Back'))
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'Group "Root folder" entered.',
      srOnly: true,
      type: 'info'
    })
  })

  it('calls onCollectionClick when a group is clicked', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    expect(onCollectionClick).toHaveBeenCalledWith({id: '1'})
  })

  it('renders a loading spinner while a group is loading', () => {
    const props = defaultProps({
      loadedGroups: ['0']
    })
    const {getByText} = render(<GroupActionDrillDown {...props} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    expect(getByText('Loading learning outcome groups')).toBeInTheDocument()
  })

  describe('action links', () => {
    it('does not render an action link until a group is clicked', async () => {
      const {queryByText, getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
      fireEvent.click(getByText('Account folder'))
      await act(async () => jest.runAllTimers())
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
      expect(getByText('Folder with groups')).toBeInTheDocument()
      fireEvent.click(getByText('Leaf folder'))
      expect(getByText('View 1 Outcome')).toBeInTheDocument()
    })
  })
})

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
import {ACCOUNT_FOLDER_ID} from '@canvas/outcomes/react/treeBrowser'

jest.useFakeTimers()

describe('GroupActionDrillDown', () => {
  let onCollectionClick, showFlashAlertSpy, setShowOutcomesView

  const collections = {
    0: {
      id: '0',
      name: 'Root folder',
      collections: [ACCOUNT_FOLDER_ID, '2'],
      parentGroupId: null
    },
    [ACCOUNT_FOLDER_ID]: {
      id: ACCOUNT_FOLDER_ID,
      name: 'Account folder',
      collections: ['100', '101'],
      outcomesCount: 7,
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
      outcomesCount: 3,
      parentGroupId: ACCOUNT_FOLDER_ID
    },
    101: {
      id: '101',
      name: 'Leaf folder',
      collections: [],
      outcomesCount: 4,
      parentGroupId: ACCOUNT_FOLDER_ID
    }
  }

  const defaultProps = (props = {}) => ({
    collections,
    rootId: '0',
    onCollectionClick,
    loadedGroups: ['0', ACCOUNT_FOLDER_ID, '2', '100', '101'],
    setShowOutcomesView,
    ...props
  })

  beforeEach(() => {
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    onCollectionClick = jest.fn()
    setShowOutcomesView = jest.fn()
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
    expect(onCollectionClick).toHaveBeenCalledWith({id: ACCOUNT_FOLDER_ID})
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

  it('calls setShowOutcomesView on unmount', () => {
    const {unmount} = render(<GroupActionDrillDown {...defaultProps()} />)
    unmount()
    expect(setShowOutcomesView).toHaveBeenCalledTimes(1)
    expect(setShowOutcomesView).toHaveBeenCalledWith(false)
  })

  describe('action links', () => {
    it('does not render an action link for the account folder', async () => {
      const {queryByText, getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      expect(queryByText('View 7 Outcomes')).not.toBeInTheDocument()
    })

    it('does not render an action link until a group is clicked', async () => {
      const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      await act(async () => jest.runAllTimers())
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
    })

    it('calls showOutcomesView upon being clicked', async () => {
      const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('View 2 Outcomes'))
      expect(setShowOutcomesView).toHaveBeenCalled()
    })

    it('hides the options and sets the display value to the group that was clicked', async () => {
      const {queryByText, getByText, getByDisplayValue} = render(
        <GroupActionDrillDown {...defaultProps()} />
      )
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Leaf folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('View 4 Outcomes'))
      expect(getByDisplayValue('Leaf folder')).toBeInTheDocument()
      expect(queryByText('View 4 Outcomes')).not.toBeInTheDocument()
    })

    it('clears the display value when the dropdown is clicked', async () => {
      const {getByPlaceholderText, getByText, getByDisplayValue} = render(
        <GroupActionDrillDown {...defaultProps()} />
      )
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('View 2 Outcomes'))
      fireEvent.click(getByDisplayValue('State folder'))
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
      expect(getByPlaceholderText('Select an outcome group')).toBeInTheDocument()
    })
  })
})

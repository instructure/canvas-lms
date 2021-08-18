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
import GroupActionDrillDown from '../GroupActionDrillDown'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {ACCOUNT_FOLDER_ID} from '@canvas/outcomes/react/treeBrowser'

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
      parentGroupId: '0'
    },
    2: {
      id: '2',
      name: 'State folder',
      collections: [],
      parentGroupId: '0'
    },
    100: {
      id: '100',
      name: 'Folder with groups',
      collections: ['101'],
      parentGroupId: ACCOUNT_FOLDER_ID
    },
    101: {
      id: '101',
      name: 'Leaf folder',
      collections: [],
      parentGroupId: ACCOUNT_FOLDER_ID
    }
  }

  const defaultProps = (props = {}) => ({
    collections,
    rootId: '0',
    onCollectionClick,
    loadedGroups: ['0', ACCOUNT_FOLDER_ID, '2', '100', '101'],
    setShowOutcomesView,
    isLoadingGroupDetail: false,
    outcomesCount: 2,
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
    it('does not render an action link for the account folder', () => {
      const {queryByText, getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
    })

    it('does not render an action link until a group is clicked', () => {
      const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
    })

    it('calls showOutcomesView upon being clicked', () => {
      const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      fireEvent.click(getByText('View 2 Outcomes'))
      expect(setShowOutcomesView).toHaveBeenCalled()
    })

    it('hides the options and sets the display value to the group that was clicked', () => {
      const {queryByText, getByText, getByDisplayValue} = render(
        <GroupActionDrillDown {...defaultProps()} />
      )
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      fireEvent.click(getByText('Leaf folder'))
      fireEvent.click(getByText('View 2 Outcomes'))
      expect(getByDisplayValue('Leaf folder')).toBeInTheDocument()
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
    })

    it('clears the display value when the dropdown is clicked', () => {
      const {getByPlaceholderText, getByText, getByDisplayValue} = render(
        <GroupActionDrillDown {...defaultProps()} />
      )
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      fireEvent.click(getByText('View 2 Outcomes'))
      fireEvent.click(getByDisplayValue('State folder'))
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
      expect(getByPlaceholderText('Select an outcome group')).toBeInTheDocument()
    })

    it('does not render an action link if isLoadingGroupDetail is true', () => {
      const {getByText, rerender, queryByText} = render(
        <GroupActionDrillDown {...defaultProps()} />
      )
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      expect(getByText('View 2 Outcomes')).toBeInTheDocument()
      rerender(<GroupActionDrillDown {...defaultProps({isLoadingGroupDetail: true})} />)
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
    })

    it('renders the link based on outcomesCount', () => {
      const {getByText} = render(<GroupActionDrillDown {...defaultProps({outcomesCount: 100})} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      fireEvent.click(getByText('Folder with groups'))
      expect(getByText('View 100 Outcomes')).toBeInTheDocument()
    })
  })
})

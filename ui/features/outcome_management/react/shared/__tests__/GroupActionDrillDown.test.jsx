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
import {render as rtlRender, fireEvent} from '@testing-library/react'
import GroupActionDrillDown from '../GroupActionDrillDown'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('GroupActionDrillDown', () => {
  let onCollectionClick, setShowOutcomesView

  const collections = {
    [ROOT_GROUP_ID]: {
      id: ROOT_GROUP_ID,
      name: 'Root folder',
      collections: [ACCOUNT_GROUP_ID, '2'],
      parentGroupId: null,
    },
    [ACCOUNT_GROUP_ID]: {
      id: ACCOUNT_GROUP_ID,
      name: 'Account folder',
      collections: ['100', '101'],
      parentGroupId: ROOT_GROUP_ID,
    },
    2: {
      id: '2',
      name: 'State folder',
      collections: [],
      parentGroupId: ROOT_GROUP_ID,
    },
    100: {
      id: '100',
      name: 'Folder with groups',
      collections: ['101'],
      parentGroupId: ACCOUNT_GROUP_ID,
    },
    101: {
      id: '101',
      name: 'Leaf folder',
      collections: [],
      parentGroupId: ACCOUNT_GROUP_ID,
    },
  }

  const defaultProps = (props = {}) => ({
    collections,
    rootId: '0',
    onCollectionClick,
    loadedGroups: ['0', ACCOUNT_GROUP_ID, '2', '100', '101'],
    setShowOutcomesView,
    isLoadingGroupDetail: false,
    outcomesCount: 2,
    showActionLinkForRoot: false,
    ...props,
  })

  beforeEach(() => {
    onCollectionClick = jest.fn()
    setShowOutcomesView = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {
      renderer = rtlRender,
      globalRootId = '',
      rootIds = [ACCOUNT_GROUP_ID, ROOT_GROUP_ID, globalRootId],
    } = {}
  ) => {
    return renderer(
      <OutcomesContext.Provider value={{env: {rootIds}}}>{children}</OutcomesContext.Provider>
    )
  }

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
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Group "Root folder" entered.',
      type: 'info',
      srOnly: true,
    })
  })

  it('calls onCollectionClick when a group is clicked', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    expect(onCollectionClick).toHaveBeenCalledWith({id: ACCOUNT_GROUP_ID})
  })

  it('renders a loading spinner while a group is loading', () => {
    const props = defaultProps({
      loadedGroups: ['0'],
    })
    const {getByText} = render(<GroupActionDrillDown {...props} />)
    fireEvent.click(getByText('Groups'))
    fireEvent.click(getByText('Account folder'))
    expect(getByText('Loading learning outcome groups')).toBeInTheDocument()
  })

  it('selects a group if selectedGroupId is provided', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps({selectedGroupId: '101'})} />)
    fireEvent.click(getByText('Groups'))
    expect(getByText('Leaf folder')).toBeInTheDocument()
  })

  it('expands the Select if showOptions is true', () => {
    const {getByText} = render(<GroupActionDrillDown {...defaultProps({showOptions: true})} />)
    expect(getByText('Account folder')).toBeInTheDocument()
  })

  it('focuses on the Select if showOptions is true', () => {
    const {getByPlaceholderText, rerender} = render(<GroupActionDrillDown {...defaultProps()} />)
    render(<GroupActionDrillDown {...defaultProps({showOptions: true})} />, {
      renderer: rerender,
    })
    expect(getByPlaceholderText('Select an outcome group')).toHaveFocus()
  })

  describe('action links', () => {
    it('does not render an action link for the folder with an id of ACCOUNT_GROUP_ID', () => {
      const {queryByText, getByText} = render(<GroupActionDrillDown {...defaultProps()} />)
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('Account folder'))
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
    })

    it('does not render an action link for the globalRootId folder', () => {
      const {queryByText, getByText} = render(<GroupActionDrillDown {...defaultProps()} />, {
        globalRootId: '2',
      })
      fireEvent.click(getByText('Groups'))
      fireEvent.click(getByText('State folder'))
      expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
    })

    describe('showActionLinkForRoot', () => {
      it('renders an action link for the root if true', () => {
        const {getByText} = render(
          <GroupActionDrillDown {...defaultProps({showActionLinkForRoot: true, rootId: '2'})} />
        )
        fireEvent.click(getByText('Groups'))
        expect(getByText('View 2 Outcomes')).toBeInTheDocument()
      })

      it('does not render an action link for the root if false', () => {
        const {getByText, queryByText} = render(
          <GroupActionDrillDown {...defaultProps({rootId: '2'})} />
        )
        fireEvent.click(getByText('Groups'))
        expect(queryByText('View 2 Outcomes')).not.toBeInTheDocument()
      })
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
      render(<GroupActionDrillDown {...defaultProps({isLoadingGroupDetail: true})} />, {
        renderer: rerender,
      })
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

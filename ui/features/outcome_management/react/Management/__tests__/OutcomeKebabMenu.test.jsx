/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {merge} from 'lodash'
import OutcomeKebabMenu from '../OutcomeKebabMenu'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

describe('OutcomeKebabMenu', () => {
  let onMenuHandlerMock
  const groupMenuTitle = 'Outcome Group Menu'
  const defaultMenuTitle = 'Menu'
  const defaultProps = (props = {}) =>
    merge(
      {
        menuTitle: groupMenuTitle,
        onMenuHandler: onMenuHandlerMock,
        canDestroy: true,
        canEdit: true,
      },
      props
    )

  const renderWithProvider = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      menuOptionForOutcomeDetailsPageFF = true,
      archiveOutcomesFF = false,
    } = {}
  ) => {
    return render(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            menuOptionForOutcomeDetailsPageFF,
            archiveOutcomesFF,
          },
        }}
      >
        {children}
      </OutcomesContext.Provider>
    )
  }

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders Kebab menu with custom menu title for screen readers if menuTitle prop provided', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    expect(getByText(groupMenuTitle)).toBeInTheDocument()
  })

  it('renders Kebab menu with default menu title for screen readers if menuTitle prop missing', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps({menuTitle: null})} />)
    expect(getByText(defaultMenuTitle)).toBeInTheDocument()
  })

  it('renders Kebab menu when menu button clicked', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    const menuButton = getByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(getByText('Edit')).toBeInTheDocument()
    expect(getByText('Remove')).toBeInTheDocument()
    expect(getByText('Move')).toBeInTheDocument()
  })

  it('renders View Description in Kebab menu if a isGroup is provided and menu button clicked', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps({isGroup: true})} />)
    const menuButton = getByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(getByText('View Description')).toBeInTheDocument()
  })

  it('does not render Add Outcomes in Kebab menu if a isGroup is not provided and menu button clicked', () => {
    const {queryByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    const menuButton = queryByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(queryByText('Add Outcomes')).not.toBeInTheDocument()
  })

  it('renders Add Outcomes in Kebab menu if a isGroup is provided and menu button clicked', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps({isGroup: true})} />)
    const menuButton = getByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(getByText('Add Outcomes')).toBeInTheDocument()
  })

  it('does not render Import Outcomes in Kebab menu if a isGroup is not provided and menu button clicked', () => {
    const {queryByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
    const menuButton = queryByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(queryByText('Import Outcomes')).not.toBeInTheDocument()
  })

  it('renders Import Outcomes in Kebab menu if a isGroup is provided and menu button clicked', () => {
    const {getByText} = render(<OutcomeKebabMenu {...defaultProps({isGroup: true})} />)
    const menuButton = getByText(groupMenuTitle)
    fireEvent.click(menuButton)
    expect(getByText('Import Outcomes')).toBeInTheDocument()
  })

  describe('Archive Outcome FF', () => {
    describe('when FF is disabled', () => {
      it('does not render Archive menu option for an outcome', () => {
        const {queryByText} = renderWithProvider(<OutcomeKebabMenu {...defaultProps()} />, {
          archiveOutcomesFF: false,
        })
        const menuButton = queryByText(groupMenuTitle)
        fireEvent.click(menuButton)
        expect(queryByText('Archive')).not.toBeInTheDocument()
      })

      it('does not render Archive menu option for an outcome group', () => {
        const {queryByText} = renderWithProvider(
          <OutcomeKebabMenu {...defaultProps({isGroup: true})} />,
          {
            archiveOutcomesFF: false,
          }
        )
        const menuButton = queryByText(groupMenuTitle)
        fireEvent.click(menuButton)
        expect(queryByText('Archive')).not.toBeInTheDocument()
      })
    })

    describe('when FF is enabled', () => {
      it('renders enabled Archive menu option for an outcome when canArchive is true', () => {
        const {getByText, getByTestId} = renderWithProvider(
          <OutcomeKebabMenu {...defaultProps({canArchive: true})} />,
          {
            archiveOutcomesFF: true,
          }
        )
        const menuButton = getByText(groupMenuTitle)
        fireEvent.click(menuButton)
        expect(getByText('Archive')).toBeInTheDocument()
        expect(getByTestId('outcome-kebab-menu-archive')).toBeInTheDocument()
      })

      it('renders disabled Archive menu option for an outcome when canArchive is false', () => {
        const {getByText, getByTestId} = renderWithProvider(
          <OutcomeKebabMenu {...defaultProps({canArchive: false})} />,
          {
            archiveOutcomesFF: true,
          }
        )
        const menuButton = getByText(groupMenuTitle)
        fireEvent.click(menuButton)
        expect(getByText('Archive')).toBeInTheDocument()
        expect(getByTestId('outcome-kebab-menu-archive-disabled')).toBeInTheDocument()
      })

      it('renders enabled Archive menu option for an outcome group', () => {
        const {getByText} = renderWithProvider(
          <OutcomeKebabMenu {...defaultProps({isGroup: true})} />,
          {
            archiveOutcomesFF: true,
          }
        )
        const menuButton = getByText(groupMenuTitle)
        fireEvent.click(menuButton)
        expect(getByText('Archive')).toBeInTheDocument()
      })
    })
  })

  describe('Menu Option for Outcome Details Page FF', () => {
    it('does not render Alignments menu option if Menu Option for Outcome Details Page FF is disabled', () => {
      const {queryByText} = renderWithProvider(
        <OutcomeKebabMenu {...defaultProps({isGroup: false})} />,
        {
          menuOptionForOutcomeDetailsPageFF: false,
        }
      )
      const menuButton = queryByText(groupMenuTitle)
      fireEvent.click(menuButton)
      expect(queryByText('Alignments')).not.toBeInTheDocument()
    })

    it('renders Alignments in Kebab menu if a isGroup is not provided and menu button clicked and FF is enabled', () => {
      const {getByText} = renderWithProvider(
        <OutcomeKebabMenu {...defaultProps({isGroup: false})} />,
        {
          menuOptionForOutcomeDetailsPageFF: true,
        }
      )
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      expect(getByText('Alignments')).toBeInTheDocument()
    })

    it('does not render Alignments in Kebab menu if a isGroup is provided and menu button clicked and FF is disabled', () => {
      const {queryByText} = renderWithProvider(
        <OutcomeKebabMenu {...defaultProps({isGroup: true})} />,
        {
          menuOptionForOutcomeDetailsPageFF: true,
        }
      )
      const menuButton = queryByText(groupMenuTitle)
      fireEvent.click(menuButton)
      expect(queryByText('Alignments')).not.toBeInTheDocument()
    })
  })

  describe('with Kebab menu open', () => {
    it('handles click on Edit item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Edit')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('edit')
    })

    it('handles click on Remove item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Remove')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('remove')
    })

    it('handles click on Move item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps()} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Move')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('move')
    })

    it('handles click on Alignments item', () => {
      const {getByText} = renderWithProvider(<OutcomeKebabMenu {...defaultProps()} />, {
        menuOptionForOutcomeDetailsPageFF: true,
      })
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Alignments')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('alignments')
    })

    it('handles click on Add Outcomes item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps({isGroup: true})} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Add Outcomes')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('add_outcomes')
    })

    it('handles click on Import Outcomes item', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps({isGroup: true})} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Import Outcomes')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('import_outcomes')
    })

    it('handles click on View Description item', () => {
      const {getByText} = render(
        <OutcomeKebabMenu {...defaultProps({isGroup: true, groupDescription: 'desc'})} />
      )
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('View Description')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('description')
    })

    it('disables View Description if groupDescription is null', () => {
      const {getByText} = render(
        <OutcomeKebabMenu {...defaultProps({isGroup: true, groupDescription: null})} />
      )
      fireEvent.click(getByText(groupMenuTitle))
      fireEvent.click(getByText('View Description'))
      expect(onMenuHandlerMock).not.toHaveBeenCalled()
    })

    it('disables View Description if groupDescription is an empty string', () => {
      const {getByText} = render(
        <OutcomeKebabMenu {...defaultProps({isGroup: true, groupDescription: ''})} />
      )
      fireEvent.click(getByText(groupMenuTitle))
      fireEvent.click(getByText('View Description'))
      expect(onMenuHandlerMock).not.toHaveBeenCalled()
    })

    it('disables View Description if groupDescription is an HTML with only spaces', () => {
      const {getByText} = render(
        <OutcomeKebabMenu
          {...defaultProps({isGroup: true, groupDescription: '<div><p>   </p></div>'})}
        />
      )
      fireEvent.click(getByText(groupMenuTitle))
      fireEvent.click(getByText('View Description'))
      expect(onMenuHandlerMock).not.toHaveBeenCalled()
    })

    it('disables View Description if groupDescription is an HTML with only &nbsp;', () => {
      const {getByText} = render(
        <OutcomeKebabMenu
          {...defaultProps({
            isGroup: true,
            groupDescription: '<div><p>&nbsp;&nbsp;&nbsp;</p></div>',
          })}
        />
      )
      fireEvent.click(getByText(groupMenuTitle))
      fireEvent.click(getByText('View Description'))
      expect(onMenuHandlerMock).not.toHaveBeenCalled()
    })

    it('does not call menuHandler if canDestroy is false', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps({canDestroy: false})} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Remove')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(0)
    })

    it('does not call menuHandler if canEdit is false', () => {
      const {getByText} = render(<OutcomeKebabMenu {...defaultProps({canEdit: false})} />)
      const menuButton = getByText(groupMenuTitle)
      fireEvent.click(menuButton)
      const menuItem = getByText('Edit')
      fireEvent.click(menuItem)
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(0)
    })
  })
})

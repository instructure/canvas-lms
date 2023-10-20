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
import {render as rtlRender, fireEvent} from '@testing-library/react'
import ManageOutcomeItem from '../ManageOutcomeItem'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {MockedProvider} from '@apollo/react-testing'
import {defaultRatingsAndCalculationMethod} from './helpers'

const render = (
  children,
  {
    canManage = true,
    isAdmin = true,
    contextId = '2',
    contextType = 'Account',
    friendlyDescriptionFF = true,
    accountLevelMasteryScalesFF = true,
    renderer = rtlRender,
  } = {}
) => {
  return renderer(
    <OutcomesContext.Provider
      value={{
        env: {
          canManage,
          isAdmin,
          contextId,
          contextType,
          friendlyDescriptionFF,
          accountLevelMasteryScalesFF,
        },
      }}
    >
      <MockedProvider mocks={[]}>{children}</MockedProvider>
    </OutcomesContext.Provider>
  )
}

describe('ManageOutcomeItem', () => {
  let onMenuHandlerMock
  let onCheckboxHandlerMock
  const {calculationMethod, calculationInt, masteryPoints, ratings} =
    defaultRatingsAndCalculationMethod
  const defaultProps = (props = {}) => ({
    linkId: '2',
    title: 'Outcome Title',
    description: 'Outcome Description',
    calculationMethod,
    calculationInt,
    masteryPoints,
    ratings,
    outcomeContextType: 'Account',
    outcomeContextId: '1',
    isChecked: false,
    removeOutcomeStatus: 'REMOVE_NOT_STARTED',
    canUnlink: true,
    onMenuHandler: onMenuHandlerMock,
    onCheckboxHandler: onCheckboxHandlerMock,
    ...props,
  })

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    onCheckboxHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders title if title prop passed', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('does not render component if title prop not passed', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({title: ''})} />)
    expect(queryByTestId('outcome-management-item')).not.toBeInTheDocument()
  })

  it('handles click on checkbox', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Select outcome Outcome Title'))
    expect(onCheckboxHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('passes selected outcome obj to checkbox onClick handler', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Select outcome Outcome Title'))
    expect(onCheckboxHandlerMock).toHaveBeenCalledWith({linkId: '2'})
  })

  it('displays right pointing caret when description is truncated', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('icon-arrow-right')).toBeInTheDocument()
  })

  it('displays disabled caret button with "not-allowed" cursor if description is a single line html with no extra formatting', () => {
    const {queryByTestId} = render(
      <ManageOutcomeItem {...defaultProps({description: '<p>The quick brown fox.</p>'})} />
    )
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveAttribute('disabled')
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveStyle('cursor: not-allowed')
  })

  it('displays down pointing caret when description is expanded for multi-line html text', () => {
    const {queryByTestId} = render(
      <ManageOutcomeItem
        {...defaultProps({
          description: '<p>aaaaaaadfhausdfhkjsadhfkjsadhfkjhsadfkjhasdfkjh</p>'.repeat(10),
        })}
      />
    )
    fireEvent.click(queryByTestId('manage-outcome-item-expand-toggle'))
    expect(queryByTestId('icon-arrow-down').closest('button')).not.toHaveAttribute('disabled')
  })

  it('expands description when user clicks on button with right pointing caret', () => {
    const {queryByTestId} = render(
      <ManageOutcomeItem {...defaultProps({description: '<p>aa</p><p>bb</p>'})} />
    )
    fireEvent.click(queryByTestId('manage-outcome-item-expand-toggle'))
    expect(queryByTestId('description-expanded')).toBeInTheDocument()
  })

  it('collapses description when user clicks on button with down pointing caret', () => {
    const {queryByTestId} = render(
      <ManageOutcomeItem {...defaultProps({description: '<p>aa</p><p>bbbb</p>'})} />
    )
    fireEvent.click(queryByTestId('manage-outcome-item-expand-toggle'))
    fireEvent.click(queryByTestId('manage-outcome-item-expand-toggle'))
    expect(queryByTestId('description-truncated')).toBeInTheDocument()
  })

  it('displays disabled caret button with "not-allowed" cursor if no description', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveAttribute('disabled')
    expect(queryByTestId('icon-arrow-right').closest('button')).toHaveStyle('cursor: not-allowed')
  })

  it('displays enabled caret button if no description and accountLevelMasteryScales is disabled', () => {
    const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({description: null})} />, {
      accountLevelMasteryScalesFF: false,
    })
    expect(queryByTestId('icon-arrow-right').closest('button')).toBeEnabled()
  })

  it('displays spinner when a remove action is pending', () => {
    const {getByTestId} = render(
      <ManageOutcomeItem {...defaultProps({removeOutcomeStatus: 'REMOVE_PENDING'})} />
    )
    expect(getByTestId('outcome-spinner')).toBeInTheDocument()
  })

  it('handles click on individual outcome -> kebab menu -> remove option', () => {
    const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Menu for outcome Outcome Title'))
    fireEvent.click(getByText('Remove'))
    expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
    expect(onMenuHandlerMock.mock.calls[0][0]).toBe('2')
    expect(onMenuHandlerMock.mock.calls[0][1]).toBe('remove')
  })

  it('toggles aria-expanded attribute', () => {
    const {queryByTestId} = render(
      <ManageOutcomeItem {...defaultProps({description: '<p>aa</p><p>bb</p>'})} />
    )
    const button = queryByTestId('manage-outcome-item-expand-toggle')
    const ariaExpandedValueBeforeClick = button.getAttribute('aria-expanded')
    expect(ariaExpandedValueBeforeClick).toBe('false')
    fireEvent.click(button)
    const ariaExpandedValueAfterClick = button.getAttribute('aria-expanded')
    expect(ariaExpandedValueAfterClick).toBe('true')
  })

  describe('Kebab menu -> edit option', () => {
    it('enables option if Friendly Description FF is enabled', () => {
      const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Menu for outcome Outcome Title'))
      fireEvent.click(getByText('Edit'))
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][0]).toBe('2')
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('edit')
    })

    it('enables option if user is admin within course context', () => {
      const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />, {
        contextType: 'Course',
        friendlyDescriptionFF: false,
      })
      fireEvent.click(getByText('Menu for outcome Outcome Title'))
      fireEvent.click(getByText('Edit'))
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][0]).toBe('2')
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('edit')
    })

    it('enables option if outcome is created within the same context', () => {
      const {getByText} = render(<ManageOutcomeItem {...defaultProps()} />, {
        contextId: '1',
        friendlyDescriptionFF: false,
      })
      fireEvent.click(getByText('Menu for outcome Outcome Title'))
      fireEvent.click(getByText('Edit'))
      expect(onMenuHandlerMock).toHaveBeenCalledTimes(1)
      expect(onMenuHandlerMock.mock.calls[0][0]).toBe('2')
      expect(onMenuHandlerMock.mock.calls[0][1]).toBe('edit')
    })
  })

  describe('With manage_outcomes permission / canManage true', () => {
    it('displays kebab menu', () => {
      const {queryByText} = render(<ManageOutcomeItem {...defaultProps()} />)
      expect(queryByText('Menu for outcome Outcome Title')).toBeInTheDocument()
    })

    it('displays checkbox', () => {
      const {queryByText} = render(<ManageOutcomeItem {...defaultProps()} />)
      expect(queryByText('Select outcome Outcome Title')).toBeInTheDocument()
    })
  })

  describe('Without manage_outcomes permission / canManage false', () => {
    it('hides kebab menu', () => {
      const {queryByText} = render(<ManageOutcomeItem {...defaultProps()} />, {
        canManage: false,
      })
      expect(queryByText('Menu for outcome Outcome Title')).not.toBeInTheDocument()
    })

    it('hides checkbox', () => {
      const {queryByText} = render(<ManageOutcomeItem {...defaultProps()} />, {
        canManage: false,
      })
      expect(queryByText('Select outcome Outcome Title')).not.toBeInTheDocument()
    })
  })

  describe('account level mastery scales FF', () => {
    describe('when feature flag disabled', () => {
      it('enables caret button even if no description', () => {
        const {queryByTestId} = render(
          <ManageOutcomeItem {...defaultProps({description: null})} />,
          {
            accountLevelMasteryScalesFF: false,
          }
        )
        expect(queryByTestId('icon-arrow-right').closest('button')).toBeEnabled()
      })
    })

    describe('when feature flag enabled', () => {
      it('disables caret button and changes cursor to "not-allowed" if no description', () => {
        const {queryByTestId} = render(<ManageOutcomeItem {...defaultProps({description: null})} />)
        expect(queryByTestId('icon-arrow-right').closest('button')).toBeDisabled()
        expect(queryByTestId('icon-arrow-right').closest('button')).toHaveStyle(
          'cursor: not-allowed'
        )
      })
    })
  })
})

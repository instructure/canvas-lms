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
import FindOutcomeItem from '../FindOutcomeItem'
import {
  IMPORT_COMPLETED,
  IMPORT_NOT_STARTED,
  IMPORT_PENDING,
} from '@canvas/outcomes/react/hooks/useOutcomesImport'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {defaultRatingsAndCalculationMethod} from '../Management/__tests__/helpers'

jest.useFakeTimers()

describe('FindOutcomeItem', () => {
  let onMenuHandlerMock
  let onImportOutcomeHandlerMock
  const {calculationMethod, calculationInt, masteryPoints, ratings} =
    defaultRatingsAndCalculationMethod
  const defaultProps = (props = {}) => ({
    id: '1',
    title: 'Outcome Title',
    description: 'Outcome Description',
    calculationMethod,
    calculationInt,
    masteryPoints,
    ratings,
    isImported: false,
    importGroupStatus: IMPORT_NOT_STARTED,
    sourceContextId: '100',
    sourceContextType: 'Account',
    onMenuHandler: onMenuHandlerMock,
    importOutcomeHandler: onImportOutcomeHandlerMock,
    ...props,
  })

  const render = (
    children,
    {friendlyDescriptionFF = true, accountLevelMasteryScalesFF = true, renderer = rtlRender} = {}
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            friendlyDescriptionFF,
            accountLevelMasteryScalesFF,
          },
        }}
      >
        {children}
      </OutcomesContext.Provider>
    )
  }

  beforeEach(() => {
    onMenuHandlerMock = jest.fn()
    onImportOutcomeHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders title if title prop passed', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('does not render component if title prop not passed', () => {
    const {queryByTestId} = render(<FindOutcomeItem {...defaultProps({title: null})} />)
    expect(queryByTestId('outcome-management-item')).not.toBeInTheDocument()
  })

  it('enables add button with Add as text if outcome is not imported', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(getByText('Add')).toBeInTheDocument()
    expect(getByText('Add outcome Outcome Title')).toBeInTheDocument()
    expect(getByText('Add').closest('button')).toBeEnabled()
  })

  it('disables add button with Added as text if outcome is imported', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps({isImported: true})} />)
    expect(getByText('Added')).toBeInTheDocument()
    expect(getByText('Added outcome Outcome Title')).toBeInTheDocument()
    expect(getByText('Added').closest('button')).toBeDisabled()
  })

  it('disables add button with Added as text if group has been imported', () => {
    const {getByText} = render(
      <FindOutcomeItem {...defaultProps({importGroupStatus: IMPORT_COMPLETED})} />
    )
    expect(getByText('Added')).toBeInTheDocument()
    expect(getByText('Added').closest('button')).toBeDisabled()
  })

  it('displays spinner for outcome if group import is pending and outcome import is not completed', () => {
    const {queryByText, getByTestId} = render(
      <FindOutcomeItem {...defaultProps({importGroupStatus: IMPORT_PENDING})} />
    )
    expect(getByTestId('outcome-import-pending')).toBeInTheDocument()
    expect(queryByText('Add')).not.toBeInTheDocument()
  })

  it('does not display spinner for outcome if group import is pending and outcome import is completed', () => {
    const {getByText, queryByTestId} = render(
      <FindOutcomeItem
        {...defaultProps({
          importGroupStatus: IMPORT_PENDING,
          importOutcomeStatus: IMPORT_COMPLETED,
        })}
      />
    )
    expect(queryByTestId('outcome-import-pending')).not.toBeInTheDocument()
    expect(getByText('Added')).toBeInTheDocument()
  })

  it('handles click on add button', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Add'))
    expect(onImportOutcomeHandlerMock).toHaveBeenCalled()
  })

  it('passes item id and sourceContextId/sourceContextType to add button handler', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Add'))
    expect(onImportOutcomeHandlerMock).toHaveBeenCalledWith('1', '100', 'Account')
  })

  it('displays right pointing caret when description is collapsed', () => {
    const {queryByTestId} = render(<FindOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('icon-arrow-right')).toBeInTheDocument()
  })

  describe('Assuming the description is over a line', () => {
    it('displays down pointing caret when description is expanded', () => {
      const {queryByTestId, getByText} = render(
        <FindOutcomeItem {...defaultProps({description: '<p>Aa</p><p>Bb</p>'})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(queryByTestId('icon-arrow-down')).toBeInTheDocument()
    })

    it('expands description when user clicks on right pointing caret', () => {
      const {queryByTestId, getByText} = render(
        <FindOutcomeItem {...defaultProps({description: '<p>Aa</p><p>Bb</p>'})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(queryByTestId('description-expanded')).toBeInTheDocument()
    })

    it('collapses description when user clicks on downward pointing caret', () => {
      const {queryByTestId, getByText} = render(
        <FindOutcomeItem {...defaultProps({description: '<p>Aa</p><p>Bb</p>'})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
      expect(queryByTestId('description-truncated')).toBeInTheDocument()
    })
  })

  it('calls onImportHandler if Add button is clicked', () => {
    const {getByText} = render(<FindOutcomeItem {...defaultProps()} />, {
      contextType: 'Course',
    })
    fireEvent.click(getByText('Add'))
    expect(onImportOutcomeHandlerMock).toHaveBeenCalled()
  })

  it('renders a friendly description when the caret is clicked and friendlyDescriptionFF is true, assuming description is over a line', () => {
    const {getByText} = render(
      <FindOutcomeItem
        {...defaultProps({
          description: '<p>Aa</p><p>Bb</p>',
          friendlyDescription: 'test friendly description',
        })}
      />,
      {
        friendlyDescriptionFF: true,
      }
    )

    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    expect(getByText('test friendly description')).toBeInTheDocument()
  })

  it('doesnt render a friendly description when the caret is clicked and friendlyDescriptionFF is false', () => {
    const {queryByText, getByText} = render(
      <FindOutcomeItem {...defaultProps({friendlyDescription: 'test friendly description'})} />,
      {
        friendlyDescriptionFF: false,
      }
    )

    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    expect(queryByText('test friendly description')).not.toBeInTheDocument()
  })

  describe('account level mastery scales FF', () => {
    describe('when feature flag disabled', () => {
      it('enables caret button even if no description', () => {
        const {queryByTestId} = render(<FindOutcomeItem {...defaultProps({description: null})} />, {
          accountLevelMasteryScalesFF: false,
        })
        expect(queryByTestId('icon-arrow-right').closest('button')).toBeEnabled()
      })
    })

    describe('when feature flag enabled', () => {
      it('disables caret button if no description', () => {
        const {queryByTestId} = render(<FindOutcomeItem {...defaultProps({description: null})} />)
        expect(queryByTestId('icon-arrow-right').closest('button')).toBeDisabled()
      })
    })
  })
})

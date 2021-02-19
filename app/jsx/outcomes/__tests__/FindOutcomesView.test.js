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
import FindOutcomesView from '../FindOutcomesView'

describe('FindOutcomesView', () => {
  let onChangeHandlerMock
  let onClearHandlerMock
  let onAddAllHandlerMock
  const defaultProps = (props = {}) => ({
    collection: {
      id: 1,
      name: 'State Standards',
      outcomesCount: 3
    },
    searchString: '123',
    onChangeHandler: onChangeHandlerMock,
    onClearHandler: onClearHandlerMock,
    onAddAllHandler: onAddAllHandlerMock,
    ...props
  })

  beforeEach(() => {
    onChangeHandlerMock = jest.fn()
    onClearHandlerMock = jest.fn()
    onAddAllHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component with the correct group name and search bar placeholder', () => {
    const {getByText, getByPlaceholderText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('State Standards')).toBeInTheDocument()
    expect(getByPlaceholderText('Search within State Standards')).toBeInTheDocument()
  })

  it('renders component with default group name and search bar placeholder if name is missing in props', () => {
    const {getByText, getByPlaceholderText} = render(
      <FindOutcomesView
        {...defaultProps({
          collection: {
            ...defaultProps().collection,
            name: null
          }
        })}
      />
    )
    expect(getByText('Outcome Group')).toBeInTheDocument()
    expect(getByPlaceholderText('Search within outcome group')).toBeInTheDocument()
  })

  it('renders component with correct number of outcomes', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('3 Outcomes')).toBeInTheDocument()
  })

  it('sets default outcomes to 0 if missing in collection', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          collection: {
            ...defaultProps().collection,
            outcomesCount: null
          }
        })}
      />
    )
    expect(getByText('0 Outcomes')).toBeInTheDocument()
  })

  it('calls onChangeHandler when users types in searchbar', () => {
    const {getByDisplayValue} = render(<FindOutcomesView {...defaultProps()} />)
    const input = getByDisplayValue('123')
    fireEvent.change(input, {target: {value: 'test'}})
    expect(onChangeHandlerMock).toHaveBeenCalled()
  })

  it('calls onClearHandler on click on clear search button', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    const btn = getByText('Clear search field')
    fireEvent.click(btn)
    expect(onClearHandlerMock).toHaveBeenCalled()
  })

  it('calls onAddAllHandler on click on "Add All Outcomes" button', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    const btn = getByText('Add All Outcomes')
    fireEvent.click(btn)
    expect(onAddAllHandlerMock).toHaveBeenCalled()
  })

  it('marks outcome as added when toggle is turned on', () => {
    const {getAllByText} = render(<FindOutcomesView {...defaultProps()} />)
    const toggle = getAllByText('Add outcome')[0].closest('label').previousSibling
    fireEvent.click(toggle)
    expect(toggle).toBeChecked()
  })

  it('marks outcome as removed when toggle is turned off', () => {
    const {getAllByText} = render(<FindOutcomesView {...defaultProps()} />)
    const toggle = getAllByText('Add outcome')[0].closest('label').previousSibling
    fireEvent.click(toggle)
    fireEvent.click(toggle)
    expect(toggle).not.toBeChecked()
  })

  it('disables "Add All Outcomes" button if number of outcomes eq 0', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          collection: {
            ...defaultProps().collection,
            outcomesCount: 0
          }
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toHaveAttribute('disabled')
  })
})

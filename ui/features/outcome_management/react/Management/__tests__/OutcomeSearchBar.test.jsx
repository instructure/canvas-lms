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
import OutcomeSearchBar from '../OutcomeSearchBar'

describe('OutcomeSearchBar', () => {
  let onChangeHandlerMock
  let onClearHandlerMock
  const defaultProps = (props = {}) => ({
    placeholder: 'Search within Outcome Group',
    searchString: 'search',
    label: 'Search label',
    enabled: true,
    onChangeHandler: onChangeHandlerMock,
    onClearHandler: onClearHandlerMock,
    ...props,
  })

  beforeEach(() => {
    onChangeHandlerMock = jest.fn()
    onClearHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows placeholder if placeholder prop passed', () => {
    const {getByPlaceholderText} = render(<OutcomeSearchBar {...defaultProps()} />)
    expect(getByPlaceholderText('Search within Outcome Group')).not.toBeNull()
  })

  it('shows custom label if label prop passed', () => {
    const {getByText} = render(<OutcomeSearchBar {...defaultProps()} />)
    expect(getByText('Search label')).not.toBeNull()
  })

  it('shows default screenReaderContent label if label prop not passed', () => {
    const {getByText} = render(<OutcomeSearchBar {...defaultProps({label: null})} />)
    expect(getByText('Search field')).not.toBeNull()
  })

  it('disables search input if enabled prop is false', () => {
    const {getByDisplayValue} = render(<OutcomeSearchBar {...defaultProps({enabled: false})} />)
    expect(getByDisplayValue('search')).toHaveAttribute('disabled')
  })

  it('shows search icon if there is no input in searchbar', () => {
    const {queryByTestId} = render(<OutcomeSearchBar {...defaultProps({searchString: ''})} />)
    expect(queryByTestId('search-icon')).toBeInTheDocument()
  })

  it('shows clear search icon if there is input in searchbar', () => {
    const {queryByTestId} = render(<OutcomeSearchBar {...defaultProps()} />)
    expect(queryByTestId('clear-search-icon')).toBeInTheDocument()
  })

  it('calls onChangeHandler when user types in searchbar', () => {
    const {getByDisplayValue} = render(<OutcomeSearchBar {...defaultProps()} />)
    const input = getByDisplayValue('search')
    fireEvent.change(input, {target: {value: 'test'}})
    expect(onChangeHandlerMock).toHaveBeenCalled()
  })

  it('calls onClearHandler when user clicks on clear search button', () => {
    const {getByText} = render(<OutcomeSearchBar {...defaultProps()} />)
    const btn = getByText('Clear search field')
    fireEvent.click(btn)
    expect(onClearHandlerMock).toHaveBeenCalled()
  })
})

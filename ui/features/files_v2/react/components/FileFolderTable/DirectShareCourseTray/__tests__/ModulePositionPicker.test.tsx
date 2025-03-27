/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import ModulePositionPicker from '../ModulePositionPicker'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  onSelectPosition: jest.fn(),
}

const renderComponent = (props = {}) =>
  render(<ModulePositionPicker {...defaultProps} {...props} />)

describe('ModulePositionPicker', () => {
  beforeEach(() => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: [
        {id: 'abc', title: 'abc', position: '1'},
        {id: 'cde', title: 'cde', position: '2'},
      ],
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  it("shows 'loading additional items' when it's still loading data", async () => {
    ;(doFetchApi as jest.Mock).mockReset()
    ;(doFetchApi as jest.Mock).mockImplementationOnce(() => new Promise(() => {}))
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'Before...')
    await userEvent.click(screen.getByText(/Before.../i))
    expect(screen.getByText(/Loading additional items.../i)).toBeInTheDocument()
  })

  it('should not show the module items unless a relative position is chosen', async () => {
    renderComponent()
    expect(screen.getByTestId('select-position')).toHaveAttribute('value', 'At the Top')
    expect(screen.queryByTestId('select-sibling')).not.toBeInTheDocument()
    expect(screen.queryByText('abc')).not.toBeInTheDocument()
    expect(screen.queryByText('cde')).not.toBeInTheDocument()
  })

  it('should show the module items when a relative position is chosen', async () => {
    renderComponent()
    expect(screen.getByTestId('select-position')).toHaveAttribute('value', 'At the Top')
    await userEvent.type(screen.getByTestId('select-position'), 'After...')
    await userEvent.click(screen.getByText(/After.../i))
    await userEvent.click(screen.getByTestId('select-sibling'))
    expect(screen.getByText('abc')).toBeInTheDocument()
    expect(screen.getByText('cde')).toBeInTheDocument()
  })

  it('should call onSelectPosition with 1 on load', () => {
    renderComponent()
    expect(defaultProps.onSelectPosition).toHaveBeenCalledWith(1)
  })

  it('should call onSelectPosition with 1 when "at the top" is chosen', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'At the Top')
    await userEvent.click(screen.getByText(/At the Top/i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(2)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(1)
  })

  it('should call onSelectPosition with null when "at the bottom" is chosen', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'At the Bottom')
    await userEvent.click(screen.getByText(/At the Bottom/i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(2)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(null)
  })

  it('should call onSelectPosition with 1 when "before" is chosen with the default module item', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'Before...')
    await userEvent.click(screen.getByText(/Before.../i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(2)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(1)
  })

  it('should call onSelectPosition with 2 when "after" is chosen with the default module item', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'After...')
    await userEvent.click(screen.getByText(/After.../i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(2)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(2)
  })

  it('should call onSelectPosition with the 1-based index of the module item when "before" is chosen with a non-default module item', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'Before...')
    await userEvent.click(screen.getByText(/Before.../i))
    await userEvent.type(screen.getByTestId('select-sibling'), 'abc')
    await userEvent.click(screen.getByText(/abc/i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(3)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(1)
  })

  it('should call onSelectPosition with the 1-based index of the module item when "after" is chosen with a non-default module item', async () => {
    renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'After...')
    await userEvent.click(screen.getByText(/After.../i))
    await userEvent.type(screen.getByTestId('select-sibling'), 'cde')
    await userEvent.click(screen.getByText(/cde/i))
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(3)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(3)
  })

  it('should reset the module items and send a new position to onSelectPosition if a new module is chosen', async () => {
    const {rerender} = renderComponent()
    await userEvent.type(screen.getByTestId('select-position'), 'After...')
    await userEvent.click(screen.getByText(/After.../i))
    await userEvent.type(screen.getByTestId('select-sibling'), 'cde')
    await userEvent.click(screen.getByText(/cde/i))
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: [
        {id: 'fgh', title: 'fgh', position: '3'},
        {id: 'ijk', title: 'ijk', position: '4'},
      ],
    })
    rerender(<ModulePositionPicker {...defaultProps} moduleId="2" />)
    expect(defaultProps.onSelectPosition).toHaveBeenCalledTimes(4)
    expect(defaultProps.onSelectPosition).toHaveBeenLastCalledWith(2)
  })
})

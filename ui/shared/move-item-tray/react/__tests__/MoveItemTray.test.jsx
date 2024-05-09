/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import MoveItemTray from '../index'

const stubs = {
  focusOnExit: jest.fn(),
  formatSaveUrl: jest.fn(),
  onMoveSuccess: jest.fn(),
  onExited: jest.fn(),
}
const defaultProps = (props = {}) => ({
  title: 'Move Item',
  items: [
    {
      id: '10',
      title: 'Foo Bar',
    },
  ],
  moveOptions: {
    siblings: [
      {id: '12', title: 'Making Cake'},
      {id: '30', title: 'Very Hard Quiz'},
    ],
  },
  focusOnExit: stubs.focusOnExit,
  formatSaveUrl: stubs.formatSaveUrl,
  onMoveSuccess: stubs.onMoveSuccess,
  onExited: stubs.onExited,
  applicationElement: () => document.getElementById('fixtures'),
  ...props,
})
const renderMoveItemTray = (props = {}) => {
  const ref = React.createRef()
  const wrapper = render(<MoveItemTray ref={ref} {...defaultProps(props)} />)

  return {ref, ...wrapper}
}

describe('MoveItemTray', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  it('renders the MoveItemTray component', () => {
    renderMoveItemTray()

    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('renders one MoveSelect component on initial open', () => {
    renderMoveItemTray()

    expect(screen.getByRole('combobox')).toBeInTheDocument()
  })

  it('open sets the state.open to true', () => {
    const {ref} = renderMoveItemTray()

    ref.current.open()

    expect(ref.current.state.open).toBe(true)
  })

  it('close sets the state.open to false', () => {
    const {ref} = renderMoveItemTray()

    ref.current.close()

    expect(ref.current.state.open).toBe(false)
  })

  it('closing the tray calls onExited', () => {
    const {ref} = renderMoveItemTray()

    ref.current.onExited()

    expect(stubs.onExited).toHaveBeenCalledTimes(1)
  })

  it('onMoveSelect calls onMoveSuccess with move data', () => {
    const {ref} = renderMoveItemTray({formatSaveUrl: () => null})

    ref.current.onMoveSelect({order: ['1', '2', '3'], groupId: '5', itemIds: ['2']})

    waitFor(() =>
      expect(stubs.onMoveSuccess).toHaveBeenCalledWith({
        data: ['1', '2', '3'],
        groupId: '5',
        itemId: undefined,
        itemIds: ['2'],
      })
    )
  })

  it('calls onFocus on the result of focusOnExit on close', () => {
    const {ref} = renderMoveItemTray()

    ref.current.onExited()
    jest.runOnlyPendingTimers()

    expect(stubs.focusOnExit).toHaveBeenCalledTimes(1)
  })
})

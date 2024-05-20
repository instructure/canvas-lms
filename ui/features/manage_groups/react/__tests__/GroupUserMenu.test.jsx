/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import {GroupUserMenu} from '../GroupUserMenu'

const defaultProps = {
  userId: 1,
  userName: 'Anakin Skywalker',
  isLeader: false,
  onRemoveFromGroup: jest.fn(),
  onRemoveAsLeader: jest.fn(),
  onSetAsLeader: jest.fn(),
  onMoveTo: jest.fn(),
}

const setup = (props = {}) => {
  return render(<GroupUserMenu {...props} />)
}

describe('GroupUserMenu', () => {
  it('renders when clicked', async () => {
    const {findByTestId, findByText} = setup(defaultProps)
    fireEvent.click(await findByTestId('groupUserMenu'))

    expect(await findByText('Remove Anakin Skywalker from group')).toBeInTheDocument()
    expect(await findByText('Set Anakin Skywalker as leader')).toBeInTheDocument()
    expect(await findByText('Move Anakin Skywalker to a new group')).toBeInTheDocument()
  })

  it('closes when clicked after opening it', async () => {
    const {findByTestId, queryByText} = setup(defaultProps)
    fireEvent.click(await findByTestId('groupUserMenu'))

    expect(queryByText('Remove Anakin Skywalker from group')).toBeInTheDocument()

    fireEvent.click(await findByTestId('groupUserMenu'))

    expect(queryByText('Remove Anakin Skywalker from group')).not.toBeInTheDocument()
  })

  it('renders the "Remove as Leader" option when the user is group leader', async () => {
    const {findByTestId, findByText} = setup({...defaultProps, isLeader: true})
    fireEvent.click(await findByTestId('groupUserMenu'))

    expect(await findByText('Remove Anakin Skywalker as leader')).toBeInTheDocument()
  })

  it('calls onRemoveFromGroup when "Remove" is clicked', async () => {
    const {findByTestId, findByText} = setup(defaultProps)
    fireEvent.click(await findByTestId('groupUserMenu'))
    fireEvent.click(await findByText('Remove Anakin Skywalker from group'))

    expect(defaultProps.onRemoveFromGroup).toHaveBeenCalledWith(defaultProps.userId)
  })

  it('calls onSetAsLeader when "Set as Leader" is clicked', async () => {
    const {findByTestId, findByText} = setup(defaultProps)
    fireEvent.click(await findByTestId('groupUserMenu'))
    fireEvent.click(await findByText('Set Anakin Skywalker as leader'))

    expect(defaultProps.onSetAsLeader).toHaveBeenCalledWith(defaultProps.userId)
  })

  it('calls onRemoveAsLeader when "Remove as Leader" is clicked', async () => {
    const {findByTestId, findByText} = setup({...defaultProps, isLeader: true})
    fireEvent.click(await findByTestId('groupUserMenu'))
    fireEvent.click(await findByText('Remove Anakin Skywalker as leader'))

    expect(defaultProps.onRemoveAsLeader).toHaveBeenCalledWith(defaultProps.userId)
  })

  it('calls onMoveTo when "Move To..." is clicked', async () => {
    const {findByTestId, findByText} = setup(defaultProps)
    fireEvent.click(await findByTestId('groupUserMenu'))
    fireEvent.click(await findByText('Move Anakin Skywalker to a new group'))

    expect(defaultProps.onMoveTo).toHaveBeenCalledWith(defaultProps.userId)
  })
})

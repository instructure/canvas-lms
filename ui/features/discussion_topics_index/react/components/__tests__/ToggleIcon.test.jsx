/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {fireEvent, render, screen} from '@testing-library/react'
import ToggleIcon from '../ToggleIcon'

const defaultProps = (props = {}) => ({
  toggled: true,
  OnIcon: <span className="onIcon" />,
  OffIcon: <span className="offIcon" />,
  onToggleOn: () => {},
  onToggleOff: () => {},
  disabled: false,
  ...props,
})

const renderToggleIcon = (props = {}) => render(<ToggleIcon {...defaultProps(props)} />)

describe('ToggleIcon', () => {
  it('renders the ToggleIcon component', () => {
    renderToggleIcon()

    expect(screen.getByRole('button')).toBeInTheDocument()
    expect(screen.getByRole('button')).toHaveClass('toggle-button')
  })

  it('adds the className to the container', () => {
    const {container} = renderToggleIcon({className: 'foo'})

    expect(container.querySelector('.foo')).toBeInTheDocument()
  })

  it('renders the on icon when toggled', () => {
    const {container} = renderToggleIcon()

    expect(container.querySelector('.onIcon')).toBeInTheDocument()
    expect(container.querySelector('.offIcon')).not.toBeInTheDocument()
  })

  it('renders the off icon when untoggled', () => {
    const {container} = renderToggleIcon({toggled: false})

    expect(container.querySelector('.onIcon')).not.toBeInTheDocument()
    expect(container.querySelector('.offIcon')).toBeInTheDocument()
  })

  it('calls onToggleOff when clicked while toggled', () => {
    const onToggleOn = jest.fn()
    const onToggleOff = jest.fn()
    const {container} = renderToggleIcon({onToggleOn, onToggleOff})

    fireEvent.click(container.querySelector('.onIcon'))

    expect(onToggleOff).toHaveBeenCalledTimes(1)
    expect(onToggleOn).toHaveBeenCalledTimes(0)
  })

  it('calls onToggleOn when clicked while untoggled', () => {
    const onToggleOn = jest.fn()
    const onToggleOff = jest.fn()
    const {container} = renderToggleIcon({onToggleOn, onToggleOff, toggled: false})

    fireEvent.click(container.querySelector('.offIcon'))

    expect(onToggleOff).toHaveBeenCalledTimes(0)
    expect(onToggleOn).toHaveBeenCalledTimes(1)
  })

  it('cannot be clicked if disabled', () => {
    const onToggleOn = jest.fn()
    const onToggleOff = jest.fn()
    const {container} = renderToggleIcon({onToggleOn, onToggleOff, disabled: true})

    fireEvent.click(container.querySelector('.onIcon'))

    expect(screen.getByRole('button')).toBeDisabled()
    expect(screen.getByRole('button')).toHaveClass('disabled-toggle-button')
    expect(onToggleOff).toHaveBeenCalledTimes(0)
    expect(onToggleOn).toHaveBeenCalledTimes(0)
  })
})

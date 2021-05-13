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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import useRCE from '../../hooks/useRCE'
import EditGroupForm from '../EditGroupForm'
import {focusChange} from './helpers'

jest.useFakeTimers()
jest.mock('../../hooks/useRCE')
useRCE.mockReturnValue([() => {}, () => 'Updated description', null, null, null])

describe('EditGroupForm', () => {
  let onCloseHandler, onSubmit
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onSubmit,
    onCloseHandler,
    ...props
  })

  beforeEach(() => {
    onCloseHandler = jest.fn()
    onSubmit = jest.fn()
  })

  it('renders form with empty data', () => {
    const {getByLabelText} = render(<EditGroupForm {...defaultProps()} />)
    expect(getByLabelText('Group Name')).toBeInTheDocument()
    expect(getByLabelText('Group Description')).toBeInTheDocument()
  })

  it('renders form with initial data', () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description'
    }
    const {getByDisplayValue} = render(<EditGroupForm {...defaultProps({initialValues})} />)
    expect(getByDisplayValue('The Group Name')).toBeInTheDocument()
  })

  it('calls onSubmit when submission', () => {
    const {getByLabelText, getByText} = render(<EditGroupForm {...defaultProps()} />)
    focusChange(getByLabelText('Group Name'), 'Group Name value')
    fireEvent.click(getByText('Save'))
    expect(onSubmit.mock.calls[0][0]).toEqual({
      title: 'Group Name value',
      description: 'Updated description'
    })
  })

  it('disables submission if form is invalid', () => {
    const {getByText, getByLabelText} = render(<EditGroupForm {...defaultProps()} />)
    focusChange(getByLabelText('Group Name'), 'a'.repeat(256))
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('only enable submission if form is edited', () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description'
    }
    const {getByText, getByLabelText} = render(<EditGroupForm {...defaultProps({initialValues})} />)
    expect(getByText('Save').closest('button')).toBeDisabled()
    focusChange(getByLabelText('Group Name'), 'New Group Name')
    expect(getByText('Save').closest('button')).toBeEnabled()
    focusChange(getByLabelText('Group Name'), initialValues.title)
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('enables submission if form is valid', () => {
    const {getByText, getByLabelText} = render(<EditGroupForm {...defaultProps()} />)
    focusChange(getByLabelText('Group Name'), 'Group Name value')
    expect(getByText('Save').closest('button')).toBeEnabled()
  })

  it('validates name', () => {
    const {getByLabelText, queryByText} = render(<EditGroupForm {...defaultProps()} />)
    const name = getByLabelText('Group Name')
    focusChange(name, '')
    expect(queryByText('This field is required')).toBeInTheDocument()
    focusChange(name, 'a')
    expect(queryByText('This field is required')).not.toBeInTheDocument()
  })

  it('shows modal if open prop true', () => {
    const {getByText} = render(<EditGroupForm {...defaultProps()} />)
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', () => {
    const {queryByText} = render(<EditGroupForm {...defaultProps({isOpen: false})} />)
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Close button click', () => {
    const {getByText} = render(<EditGroupForm {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = render(<EditGroupForm {...defaultProps()} />)
    const cancelBtn = getByText('Cancel')
    fireEvent.click(cancelBtn)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })
})

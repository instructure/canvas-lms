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

import {fireEvent, render, act} from '@testing-library/react'
import React from 'react'
import GroupEditForm from '../GroupEditForm'
import {focusChange} from './helpers'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.useFakeTimers()

describe('GroupEditForm', () => {
  let onCloseHandler, onSubmit
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onSubmit,
    onCloseHandler,
    ...props,
  })

  beforeEach(() => {
    onCloseHandler = jest.fn()
    onSubmit = jest.fn()
  })
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders form with empty data', () => {
    const {getByLabelText, getByText} = render(<GroupEditForm {...defaultProps()} />)
    expect(getByLabelText('Group Name')).toBeInTheDocument()
    expect(getByText('Group Description')).toBeInTheDocument()
  })

  it('renders form with initial title', () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description',
    }
    const {getByDisplayValue} = render(<GroupEditForm {...defaultProps({initialValues})} />)
    expect(getByDisplayValue('The Group Name')).toBeInTheDocument()
  })

  it('renders form with initial description', async () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description',
    }

    const {getByDisplayValue} = render(<GroupEditForm {...defaultProps({initialValues})} />)
    await act(async () => jest.runAllTimers())
    expect(getByDisplayValue('The Group Description')).toBeInTheDocument()
  })

  it('calls onSubmit when submission', async () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description',
    }
    const {getByLabelText, getByText} = render(<GroupEditForm {...defaultProps({initialValues})} />)
    await act(async () => jest.runAllTimers())
    focusChange(getByLabelText('Group Name'), 'New group name')
    focusChange(getByText('The Group Description'), 'Updated description')
    fireEvent.click(getByText('Save'))
    expect(onSubmit.mock.calls[0][0]).toEqual({
      title: 'New group name',
      description: 'Updated description',
    })
  })

  it('disables submission if form is invalid', () => {
    const {getByText, getByLabelText} = render(<GroupEditForm {...defaultProps()} />)
    focusChange(getByLabelText('Group Name'), 'a'.repeat(256))
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('only enable submission if form is edited', () => {
    const initialValues = {
      title: 'The Group Name',
      description: 'The Group Description',
    }
    const {getByText, getByLabelText} = render(<GroupEditForm {...defaultProps({initialValues})} />)
    expect(getByText('Save').closest('button')).toBeDisabled()
    focusChange(getByLabelText('Group Name'), 'New Group Name')
    expect(getByText('Save').closest('button')).toBeEnabled()
    focusChange(getByLabelText('Group Name'), initialValues.title)
    expect(getByText('Save').closest('button')).toBeDisabled()
  })

  it('enables submission if form is valid', () => {
    const {getByText, getByLabelText} = render(<GroupEditForm {...defaultProps()} />)
    focusChange(getByLabelText('Group Name'), 'Group Name value')
    expect(getByText('Save').closest('button')).toBeEnabled()
  })

  it('validates name', () => {
    const {getByLabelText, queryByText} = render(<GroupEditForm {...defaultProps()} />)
    const name = getByLabelText('Group Name')
    focusChange(name, '')
    expect(queryByText('This field is required')).toBeInTheDocument()
    focusChange(name, 'a')
    expect(queryByText('This field is required')).not.toBeInTheDocument()
  })

  it('shows modal if open prop true', () => {
    const {getByText} = render(<GroupEditForm {...defaultProps()} />)
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', () => {
    const {queryByText} = render(<GroupEditForm {...defaultProps({isOpen: false})} />)
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Close button click', () => {
    const {getByText} = render(<GroupEditForm {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = render(<GroupEditForm {...defaultProps()} />)
    const cancelBtn = getByText('Cancel')
    fireEvent.click(cancelBtn)
    expect(onCloseHandler).toHaveBeenCalledTimes(1)
  })
})

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
import {within} from '@testing-library/dom'
import CreateOutcomeModal from 'jsx/outcomes/CreateOutcomeModal'

jest.mock('jsx/shared/rce/RichContentEditor')
jest.useFakeTimers()

describe('CreateOutcomeModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows modal if isOpen prop true', () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    expect(getByText('Create Outcome')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = render(<CreateOutcomeModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Create Outcome')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Create button click', () => {
    const {getByLabelText, getByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Create'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', () => {
    const {getByRole} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.click(within(getByRole('dialog')).getByText('Close'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('does not show error message below Name field on initial load and disables Create button', () => {
    const {getByText, queryByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(queryByText('Cannot be blank')).not.toBeInTheDocument()
  })

  it('shows error message below Name field if no name after user makes changes to title and disables Create button', () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: '123'}})
    fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name includes only spaces and disables Create button', () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name > 255 characters and disables Create button', () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
  })

  it('shows error message below displayName field if displayName > 255 characters and disables Create button', () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
  })
})

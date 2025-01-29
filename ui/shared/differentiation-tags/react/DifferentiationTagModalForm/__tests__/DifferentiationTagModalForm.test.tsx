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
import userEvent from '@testing-library/user-event'
import DifferentiationTagModalForm from '../DifferentiationTagModalForm'
import type {DifferentiationTagSet} from '../../types'
import type {DifferentiationTagModalFormProps} from '../DifferentiationTagModalForm'

describe('DifferentiationTagModalForm', () => {
  const onCloseMock = jest.fn()
  const mockTagSet: DifferentiationTagSet = {
    id: 1,
    name: 'Test Tag Set',
    groups: [
      {id: 1, name: 'Group 1'},
      {id: 2, name: 'Group 2'},
    ],
  }

  const renderComponent = (props: Partial<DifferentiationTagModalFormProps> = {}) => {
    const defaultProps = {
      isOpen: props.isOpen ?? true,
      mode: 'create',
      onClose: onCloseMock,
      ...props,
    } as DifferentiationTagModalFormProps

    render(<DifferentiationTagModalForm {...defaultProps} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the modal when isOpen is true', () => {
    renderComponent()
    expect(screen.getByText('Create Tag')).toBeInTheDocument()
  })

  it('does not render when isOpen is false', () => {
    renderComponent({isOpen: false})
    expect(screen.queryByText('Create Tag')).not.toBeInTheDocument()
  })

  describe('create mode', () => {
    it('shows create title and save button', () => {
      renderComponent()
      expect(screen.getByText('Create Tag')).toBeInTheDocument()
      expect(screen.getByText('Save')).toBeInTheDocument()
    })

    it('displays tag set selector', () => {
      renderComponent()
      expect(screen.getByText('Tag Set*')).toBeInTheDocument()
    })

    it('does not show variant radio buttons', () => {
      renderComponent()
      expect(screen.queryByText(/Future radio button/)).not.toBeInTheDocument()
    })
  })

  describe('edit mode', () => {
    it('shows edit title and update button', () => {
      renderComponent({mode: 'edit', differentiationTagSet: mockTagSet})
      expect(screen.getByText('Edit Tag')).toBeInTheDocument()
      expect(screen.getByText('Update')).toBeInTheDocument()
    })

    it('displays variant radio buttons', () => {
      renderComponent({mode: 'edit', differentiationTagSet: mockTagSet})
      expect(screen.getByText(/Future radio button/)).toBeInTheDocument()
    })

    it('shows associated groups', () => {
      renderComponent({mode: 'edit', differentiationTagSet: mockTagSet})
      expect(screen.getByText('Group 1 (ID: 1)')).toBeInTheDocument()
      expect(screen.getByText('Group 2 (ID: 2)')).toBeInTheDocument()
    })
  })

  it('displays info alert about tag visibility', () => {
    renderComponent()
    expect(screen.getByText(/Tags are not visible to students/)).toBeInTheDocument()
  })

  it('closes when clicking close button', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: 'Close'}))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('closes when clicking cancel button', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('disables submit button during submission', async () => {
    renderComponent()
    const submitButton = screen.getByRole('button', {name: 'Save'})

    await userEvent.click(submitButton)

    expect(submitButton).toBeDisabled()
    expect(submitButton).toHaveTextContent('Submitting...')
  })
})

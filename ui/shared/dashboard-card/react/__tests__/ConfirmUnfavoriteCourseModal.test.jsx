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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfirmUnfavoriteCourseModal from '../ConfirmUnfavoriteCourseModal'

describe('ConfirmUnfavoriteCourseModal', () => {
  const defaultProps = {
    courseName: 'defense against the dark arts',
    onConfirm: jest.fn(),
    onClose: jest.fn(),
    onEntered: jest.fn(),
  }

  let modalRef

  beforeEach(() => {
    defaultProps.onConfirm.mockClear()
    defaultProps.onClose.mockClear()
    defaultProps.onEntered.mockClear()
  })

  const renderModal = (props = {}) => {
    const mergedProps = {...defaultProps, ...props}
    return render(
      <ConfirmUnfavoriteCourseModal
        ref={ref => {
          modalRef = ref
        }}
        {...mergedProps}
      />,
    )
  }

  const showModal = async () => {
    modalRef.show()
    await waitFor(() => {
      expect(defaultProps.onEntered).toHaveBeenCalled()
    })
  }

  const getSubmitButton = () => screen.getByRole('button', {name: /submit/i})
  const getCloseButton = () => screen.getByRole('button', {name: 'Close'})

  describe('show()', () => {
    it('opens the modal', async () => {
      renderModal()
      await showModal()
      expect(screen.getByRole('dialog', {name: 'Confirm unfavorite course'})).toBeInTheDocument()
    })
  })

  describe('hide()', () => {
    it('closes the modal', async () => {
      renderModal()
      await showModal()
      modalRef.hide()
      await waitFor(() => {
        expect(defaultProps.onClose).toHaveBeenCalled()
      })
    })
  })

  describe('handleSubmitUnfavorite()', () => {
    it('calls onConfirm prop when Submit button is clicked', async () => {
      renderModal()
      await showModal()
      await userEvent.click(getSubmitButton())
      expect(defaultProps.onConfirm).toHaveBeenCalled()
    })

    it('hides the modal after submitting', async () => {
      renderModal()
      await showModal()
      await userEvent.click(getSubmitButton())
      await waitFor(() => {
        expect(defaultProps.onClose).toHaveBeenCalled()
      })
    })
  })

  describe('modal interactions', () => {
    it('closes modal when Close button is clicked', async () => {
      renderModal()
      await showModal()
      await userEvent.click(getCloseButton())
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })
})

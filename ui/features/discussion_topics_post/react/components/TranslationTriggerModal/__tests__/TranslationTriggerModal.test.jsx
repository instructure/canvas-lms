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

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { TranslationTriggerModal } from '../TranslationTriggerModal'

describe('TranslationTriggerModal', () => {
  let closeModal, closeModalAndKeepTranslations, closeModalAndRemoveTranslations

  beforeEach(() => {
    closeModal = jest.fn()
    closeModalAndKeepTranslations = jest.fn()
    closeModalAndRemoveTranslations = jest.fn()
  })

  const renderModal = (isModalOpen) => {
    render(
      <TranslationTriggerModal
        isModalOpen={isModalOpen}
        closeModal={closeModal}
        closeModalAndKeepTranslations={closeModalAndKeepTranslations}
        closeModalAndRemoveTranslations={closeModalAndRemoveTranslations}
      />
    )
  }

  it('should not be visible when isModalOpen is false', () => {
    renderModal(false)
    expect(screen.queryByText('Are you sure you want to close?')).not.toBeInTheDocument()
  })

  it('should be visible when isModalOpen is true', () => {
    renderModal(true)
    expect(screen.getByText('Are you sure you want to close?')).toBeInTheDocument()
  })

  it('should call closeModal when clicking the Cancel button', async () => {
    renderModal(true)
    const cancelButton = screen.getByRole('button', { name: /cancel/i })
    await userEvent.click(cancelButton)
    expect(closeModal).toHaveBeenCalledTimes(1)
  })

  it('should call closeModalAndKeepTranslations when clicking the Keep Translations button', async () => {
    renderModal(true)
    const keepButton = screen.getByRole('button', { name: /close and keep translations/i })
    await userEvent.click(keepButton)
    expect(closeModalAndKeepTranslations).toHaveBeenCalledTimes(1)
  })

  it('should call closeModalAndRemoveTranslations when clicking the Remove Translations button', async () => {
    renderModal(true)
    const removeButton = screen.getByRole('button', { name: /close and remove translations/i })
    await userEvent.click(removeButton)
    expect(closeModalAndRemoveTranslations).toHaveBeenCalledTimes(1)
  })
})

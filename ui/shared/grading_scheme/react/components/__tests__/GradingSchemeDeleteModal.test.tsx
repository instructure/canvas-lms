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
import {DefaultGradingScheme} from './fixtures'
import type {GradingSchemeDeleteModalProps} from '../GradingSchemeDeleteModal'
import GradingSchemeDeleteModal from '../GradingSchemeDeleteModal'

describe('GradingSchemeDeleteModal', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })
  const renderGradingSchemeDeleteModal = (props: Partial<GradingSchemeDeleteModalProps> = {}) => {
    const handleGradingSchemeDelete = jest.fn()
    const handleCloseDeleteModal = jest.fn()

    const funcs = render(
      <GradingSchemeDeleteModal
        open={true}
        selectedGradingScheme={DefaultGradingScheme}
        deletingGradingScheme={false}
        handleGradingSchemeDelete={handleGradingSchemeDelete}
        handleCloseDeleteModal={handleCloseDeleteModal}
        {...props}
      />
    )
    return {...funcs, handleGradingSchemeDelete, handleCloseDeleteModal}
  }
  it('should render a modal', () => {
    const {getByTestId} = renderGradingSchemeDeleteModal()
    expect(getByTestId('grading-scheme-delete-modal')).toBeInTheDocument()
  })

  it('should call the handleCloseDeleteModal button when the close button is clicked', () => {
    const {getByTestId, handleCloseDeleteModal} = renderGradingSchemeDeleteModal()
    const closeBtn = getByTestId('grading-scheme-delete-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleCloseDeleteModal).toHaveBeenCalled()
  })

  it('should render the title of the grading scheme in the modal', () => {
    const {getByTestId} = renderGradingSchemeDeleteModal()
    expect(getByTestId('grading-scheme-delete-modal-title')).toHaveTextContent(
      `Delete ${DefaultGradingScheme.title}`
    )
  })

  it('should call the handleGradingSchemeDelete button when the delete button is clicked', () => {
    const {getByTestId, handleGradingSchemeDelete} = renderGradingSchemeDeleteModal()
    const deleteButton = getByTestId('grading-scheme-delete-modal-delete-button')
    fireEvent.click(deleteButton)
    expect(handleGradingSchemeDelete).toHaveBeenCalledWith(DefaultGradingScheme.id)
  })
})

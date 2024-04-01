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
import GradingSchemeViewModal, {type GradingSchemeViewModalProps} from '../GradingSchemeViewModal'

function renderGradingSchemeViewModal(props: Partial<GradingSchemeViewModalProps> = {}) {
  const handleClose = jest.fn()
  const openDeleteModal = jest.fn()
  const editGradingScheme = jest.fn()
  const canManageScheme = jest.fn()

  const utils = render(
    <GradingSchemeViewModal
      open={true}
      gradingScheme={DefaultGradingScheme}
      handleClose={handleClose}
      openDeleteModal={openDeleteModal}
      editGradingScheme={editGradingScheme}
      canManageScheme={canManageScheme}
      {...props}
    />
  )

  return {
    ...utils,
    handleClose,
    openDeleteModal,
    editGradingScheme,
    canManageScheme,
  }
}

describe('GradingSchemeViewModal', () => {
  it('should render a modal', () => {
    const {getByTestId} = renderGradingSchemeViewModal()
    expect(getByTestId('grading-scheme-view-modal')).toBeInTheDocument()
  })

  it('should call the handleClose function when the close button is clicked', () => {
    const {getByTestId, handleClose} = renderGradingSchemeViewModal()
    const closeBtn = getByTestId('grading-scheme-view-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleClose).toHaveBeenCalled()
  })

  it('should render the title of the grading scheme in the modal', () => {
    const {getByTestId} = renderGradingSchemeViewModal()
    expect(getByTestId('grading-scheme-view-modal-title')).toHaveTextContent(
      `${DefaultGradingScheme.title}`
    )
  })
})

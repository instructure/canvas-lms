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
import {render, fireEvent} from '@testing-library/react'
import GradingSchemeEditModal, {type GradingSchemeEditModalProps} from '../GradingSchemeEditModal'
import {DefaultGradingScheme} from './fixtures'

function renderGradingSchemeEditModal(props: Partial<GradingSchemeEditModalProps> = {}) {
  const handleCancelEdit = jest.fn()
  const openDeleteModal = jest.fn()
  const handleUpdateScheme = jest.fn()

  const utils = render(
    <GradingSchemeEditModal
      open={true}
      gradingScheme={DefaultGradingScheme}
      handleCancelEdit={handleCancelEdit}
      openDeleteModal={openDeleteModal}
      handleUpdateScheme={handleUpdateScheme}
      defaultGradingSchemeTemplate={DefaultGradingScheme}
      defaultPointsGradingScheme={DefaultGradingScheme}
      viewingFromAccountManagementPage={true}
      isCourseDefault={false}
      {...props}
    />
  )

  return {
    ...utils,
    handleCancelEdit,
    openDeleteModal,
    handleUpdateScheme,
  }
}

describe('GradingSchemeEditModal', () => {
  it('should render a modal', () => {
    const {getByTestId} = renderGradingSchemeEditModal()
    expect(getByTestId('grading-scheme-edit-modal')).toBeInTheDocument()
  })

  it('should call the handleCancelEdit function when the close button is clicked', () => {
    const {getByTestId, handleCancelEdit} = renderGradingSchemeEditModal()
    const closeBtn = getByTestId('grading-scheme-edit-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleCancelEdit).toHaveBeenCalled()
  })

  it('should render the title of the grading scheme in the modal', () => {
    const {getByTestId} = renderGradingSchemeEditModal()
    expect(getByTestId('grading-scheme-edit-modal-title')).toHaveTextContent(
      `${DefaultGradingScheme.title}`
    )
  })

  it('should call the handleUpdateScheme function when the update button is clicked', () => {
    const {getByTestId, handleUpdateScheme} = renderGradingSchemeEditModal()
    const updateButton = getByTestId('grading-scheme-edit-modal-update-button')
    fireEvent.click(updateButton)
    const modifiedGradingScheme = {
      data: DefaultGradingScheme.data,
      pointsBased: DefaultGradingScheme.points_based,
      scalingFactor: DefaultGradingScheme.scaling_factor,
      title: DefaultGradingScheme.title,
    }
    expect(handleUpdateScheme).toHaveBeenCalledWith(modifiedGradingScheme, DefaultGradingScheme.id)
  })

  it('should call the update scheme with updated title when the title is changed', () => {
    const {getByTestId, handleUpdateScheme} = renderGradingSchemeEditModal()
    const titleInput = getByTestId('grading-scheme-name-input')
    fireEvent.change(titleInput, {target: {value: 'New Title'}})
    const updateButton = getByTestId('grading-scheme-edit-modal-update-button')
    fireEvent.click(updateButton)
    const modifiedGradingScheme = {
      data: DefaultGradingScheme.data,
      pointsBased: DefaultGradingScheme.points_based,
      scalingFactor: DefaultGradingScheme.scaling_factor,
      title: 'New Title',
    }
    expect(handleUpdateScheme).toHaveBeenCalledWith(modifiedGradingScheme, DefaultGradingScheme.id)
  })

  it('should call the openDeleteModal function when the delete button is clicked', () => {
    const {getByTestId, openDeleteModal} = renderGradingSchemeEditModal()
    const deleteButton = getByTestId('grading-scheme-edit-modal-delete-button')
    fireEvent.click(deleteButton)
    expect(openDeleteModal).toHaveBeenCalledWith(DefaultGradingScheme)
  })
})

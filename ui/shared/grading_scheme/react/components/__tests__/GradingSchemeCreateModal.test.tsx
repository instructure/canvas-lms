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
import type {GradingSchemeCreateModalProps} from '../GradingSchemeCreateModal'
import GradingSchemeCreateModal from '../GradingSchemeCreateModal'

describe('GradingSchemeCreateModal', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })
  const renderGradingSchemeCreateModal = (props: Partial<GradingSchemeCreateModalProps> = {}) => {
    const handleCreateScheme = jest.fn()
    const handleCancelCreate = jest.fn()

    const funcs = render(
      <GradingSchemeCreateModal
        open={true}
        handleCreateScheme={handleCreateScheme}
        defaultGradingSchemeTemplate={DefaultGradingScheme}
        defaultPointsGradingScheme={DefaultGradingScheme}
        archivedGradingSchemesEnabled={false}
        handleCancelCreate={handleCancelCreate}
        {...props}
      />
    )
    return {...funcs, handleCreateScheme, handleCancelCreate}
  }
  it('should render a form with grading scheme inputs', () => {
    const {getByTestId} = renderGradingSchemeCreateModal()
    expect(getByTestId('grading-scheme-create-modal')).toBeInTheDocument()
  })

  it('should call the handleCancelCreate button when the close button is clicked', () => {
    const {getByTestId, handleCancelCreate} = renderGradingSchemeCreateModal()
    const closeBtn = getByTestId('grading-scheme-create-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleCancelCreate).toHaveBeenCalled()
  })

  it('should call the handleCreateScheme button when the form is submitted with a name', () => {
    const {getByTestId, handleCreateScheme} = renderGradingSchemeCreateModal()
    const saveButton = getByTestId('grading-scheme-create-modal-save-button')
    const input = getByTestId('grading-scheme-name-input') as HTMLInputElement
    fireEvent.change(input, {target: {value: 'New Scheme'}})
    saveButton.click()
    expect(handleCreateScheme).toHaveBeenCalled()
  })

  it('should not call the handleCreateScheme button when the form is submitted without a name', () => {
    const {getByTestId, handleCreateScheme} = renderGradingSchemeCreateModal()
    const saveButton = getByTestId('grading-scheme-create-modal-save-button').children[0]
    fireEvent.click(saveButton)
    expect(handleCreateScheme).not.toHaveBeenCalled()
  })

  it('should call the cancel function button when the cancel button is clicked', () => {
    const {getByTestId, handleCancelCreate} = renderGradingSchemeCreateModal()
    const cancelButton = getByTestId('grading-scheme-create-modal-cancel-button')
    cancelButton.click()
    expect(handleCancelCreate).toHaveBeenCalled()
  })
})

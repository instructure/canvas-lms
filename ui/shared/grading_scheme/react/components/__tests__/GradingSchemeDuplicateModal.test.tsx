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
import GradingSchemeDuplicateModal from '../GradingSchemeDuplicateModal'
import {DefaultGradingScheme} from './fixtures'

function renderGradingSchemeDuplicateModal() {
  const handleCloseDuplicateModal = jest.fn()
  const handleDuplicateScheme = jest.fn()

  const utils = render(
    <GradingSchemeDuplicateModal
      open={true}
      creatingGradingScheme={false}
      selectedGradingScheme={DefaultGradingScheme}
      handleCloseDuplicateModal={handleCloseDuplicateModal}
      handleDuplicateScheme={handleDuplicateScheme}
    />
  )

  return {
    ...utils,
    handleCloseDuplicateModal,
    handleDuplicateScheme,
  }
}

describe('GradingSchemeDuplicateModal', () => {
  it('should render a modal', () => {
    const {getByTestId} = renderGradingSchemeDuplicateModal()
    expect(getByTestId('grading-scheme-duplicate-modal')).toBeInTheDocument()
  })

  it('should call the handleCloseDuplicateModal function when the close button is clicked', () => {
    const {getByTestId, handleCloseDuplicateModal} = renderGradingSchemeDuplicateModal()
    const closeBtn = getByTestId('grading-scheme-duplicate-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleCloseDuplicateModal).toHaveBeenCalled()
  })

  it('should render the title of the grading scheme in the modal', () => {
    const {getByTestId} = renderGradingSchemeDuplicateModal()
    expect(getByTestId('grading-scheme-duplicate-modal-title')).toHaveTextContent(
      `Duplicate ${DefaultGradingScheme.title}`
    )
  })

  it('should call the handleGradingSchemeDuplicate function when the duplicate button is clicked', () => {
    const {getByTestId, handleDuplicateScheme} = renderGradingSchemeDuplicateModal()
    const duplicateButton = getByTestId('grading-scheme-duplicate-modal-duplicate-button')
    fireEvent.click(duplicateButton)
    expect(handleDuplicateScheme).toHaveBeenCalledWith(DefaultGradingScheme)
  })
})

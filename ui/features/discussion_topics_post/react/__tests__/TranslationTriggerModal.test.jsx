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
import { render, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {TranslationTriggerModal} from "../components/TranslationTriggerModal/TranslationTriggerModal";
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('TranslationTriggerModal', () => {
  const mockCloseModal = jest.fn()
  const mockCloseModalAndKeepTranslations = jest.fn()
  const mockCloseModalAndRemoveTranslations = jest.fn()

  const getProps = (isModalOpen) => {
    return {
      isModalOpen,
      closeModal: mockCloseModal,
      closeModalAndKeepTranslations: mockCloseModalAndKeepTranslations,
      closeModalAndRemoveTranslations: mockCloseModalAndRemoveTranslations
    }
  }

  it('should render the modal when isModalOpen is true', () => {
    const { getByText } = render(<TranslationTriggerModal {...getProps(true)} />)
    expect(getByText('Are you sure you want to close?')).toBeInTheDocument()
  })

  it('should not render the modal when isModalOpen is false', () => {
    const { queryByText } = render(<TranslationTriggerModal {...getProps(false)} />)
    expect(queryByText('Are you sure you want to close?')).not.toBeInTheDocument()
  })

  it('should call closeModal when the CloseButton is clicked', () => {
    const {getByTestId} = render(<TranslationTriggerModal {...getProps(true)} />)
    fireEvent.click(getByTestId('translations-modal-close-button').querySelector('button'))
    expect(mockCloseModal).toHaveBeenCalled()
  })

  it('should call closeModal when the Cancel button is clicked', () => {
    const { getByText } = render(<TranslationTriggerModal {...getProps(true)} />)
    fireEvent.click(getByText('Cancel'))
    expect(mockCloseModal).toHaveBeenCalled()
  })

  it('should call closeModalAndKeepTranslations when the Close and Keep Translations button is clicked', () => {
    const { getByText } = render(<TranslationTriggerModal {...getProps(true)} />)
    fireEvent.click(getByText('Close and Keep Translations'))
    expect(mockCloseModalAndKeepTranslations).toHaveBeenCalled()
  })

  it('should call closeModalAndRemoveTranslations when the Close and Remove Translations button is clicked', () => {
    const { getByText } = render(<TranslationTriggerModal {...getProps(true)} />)
    fireEvent.click(getByText('Close and Remove Translations'))
    expect(mockCloseModalAndRemoveTranslations).toHaveBeenCalled()
  })

  afterAll(() => {
    mockCloseModal.mockClear()
    mockCloseModalAndKeepTranslations.mockClear()
    mockCloseModalAndRemoveTranslations.mockClear()
  })
})


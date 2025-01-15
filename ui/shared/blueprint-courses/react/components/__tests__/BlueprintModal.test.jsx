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
import {render, screen} from '@testing-library/react'
import BlueprintModal from '../BlueprintModal'

describe('BlueprintModal', () => {
  const defaultProps = {
    isOpen: true,
  }

  const renderModal = (props = defaultProps, children = <p>content</p>) => {
    return render(<BlueprintModal {...props}>{children}</BlueprintModal>)
  }

  beforeEach(() => {
    const appElement = document.createElement('div')
    appElement.id = 'application'
    document.body.appendChild(appElement)
  })

  afterEach(() => {
    const appElement = document.getElementById('application')
    if (appElement) {
      appElement.remove()
    }
  })

  it('renders the modal content', () => {
    renderModal()
    expect(screen.getByText('content')).toBeInTheDocument()
  })

  it('renders only the Done button when there are no changes', () => {
    renderModal()
    const doneButton = screen.getByTestId('done-button')
    expect(doneButton).toBeInTheDocument()
    expect(screen.queryByTestId('save-button')).not.toBeInTheDocument()
    expect(screen.queryByTestId('cancel-button')).not.toBeInTheDocument()
  })

  it('renders Checkbox, Save, and Cancel buttons when there are changes', () => {
    const props = {
      ...defaultProps,
      hasChanges: true,
      willAddAssociations: true,
      canAutoPublishCourses: true,
    }
    renderModal(props)

    expect(screen.getByTestId('publish-courses-checkbox')).toBeInTheDocument()
    expect(screen.getByTestId('save-button')).toBeInTheDocument()
    expect(screen.getByTestId('cancel-button')).toBeInTheDocument()
  })

  it('renders only the Done button when saving is in progress', () => {
    const props = {
      ...defaultProps,
      hasChanges: true,
      isSaving: true,
    }
    renderModal(props)

    expect(screen.getByTestId('done-button')).toBeInTheDocument()
    expect(screen.queryByTestId('save-button')).not.toBeInTheDocument()
    expect(screen.queryByTestId('cancel-button')).not.toBeInTheDocument()
  })
})

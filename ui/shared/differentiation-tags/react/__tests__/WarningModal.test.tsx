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
import {render, fireEvent} from '@testing-library/react'
import {DeleteTagWarningModal, RemoveTagWarningModal} from '../WarningModal'

describe('DeleteTagWarningModal', () => {
  const onCloseMock = jest.fn()
  const onContinueMock = jest.fn()
  const defaultProps = {
    open: true,
    onClose: onCloseMock,
    onContinue: onContinueMock,
  }

  const setup = (props = defaultProps) => {
    return render(<DeleteTagWarningModal {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the delete tag warning modal text', () => {
    const {getByText} = setup()
    expect(getByText(/Deleting this tag preserves past assignments/i)).toBeInTheDocument()
  })

  it('calls onClose when the Cancel button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Cancel'))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('calls onContinue when the Confirm button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Confirm'))
    expect(onContinueMock).toHaveBeenCalled()
  })
})

describe('RemoveTagWarningModal', () => {
  const onCloseMock = jest.fn()
  const onContinueMock = jest.fn()
  const defaultProps = {
    open: true,
    onClose: onCloseMock,
    onContinue: onContinueMock,
  }

  const setup = (props = defaultProps) => {
    return render(<RemoveTagWarningModal {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the remove tag warning modal text', () => {
    const {getByText} = setup()
    expect(
      getByText(/Removing the tag from a student preserves past assignments/i),
    ).toBeInTheDocument()
  })

  it('calls onClose when the Cancel button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Cancel'))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('calls onContinue when the Confirm button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Confirm'))
    expect(onContinueMock).toHaveBeenCalled()
  })
})

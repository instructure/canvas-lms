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
import {MissingSectionsWarningModal} from "../MissingSectionsWarningModal";

const defaultProps = {
  sections: [
    {
      id: '1',
      name: 'Section 1',
    },
    {
      id: '2',
      name: 'Section 2',
    },
    {
      id: '3',
      name: 'Section 3',
    },
  ],
  onClose: jest.fn(),
  onContinue: jest.fn(e => e.preventDefault()),
}

const setup = (props = defaultProps) => {
  return render(<MissingSectionsWarningModal {...props} />)
}

describe('MissingSectionsWarningModal', () => {
  it('renders the modal', () => {
    const {getByText} = setup()

    expect(getByText('Not all sections will be assigned this item.')).toBeInTheDocument()
  })

  it('renders the list of sections', () => {
    const {getByText} = setup()

    expect(getByText('Section 1')).toBeInTheDocument()
    expect(getByText('Section 2')).toBeInTheDocument()
    expect(getByText('Section 3')).toBeInTheDocument()
  })

  it('calls onClose when the Go Back button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Go Back'))

    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('calls onContinue when the Continue button is clicked', () => {
    const {getByText} = setup()

    fireEvent.click(getByText('Continue'))

    expect(defaultProps.onContinue).toHaveBeenCalled()
  })
})

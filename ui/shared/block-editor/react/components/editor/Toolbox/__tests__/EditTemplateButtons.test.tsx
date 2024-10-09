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
import {render} from '@testing-library/react'
import {EditTemplateButtons} from '../EditTemplateButtons'

const defaultProps = {
  templateId: '1',
  onEditTemplate: jest.fn(),
  onDeleteTemplate: jest.fn(),
}

const renderComponent = (props = {}) => {
  return render(<EditTemplateButtons {...defaultProps} {...props} />)
}

describe('EditTemplateButtons', () => {
  it('renders', () => {
    const {getByText} = renderComponent()

    expect(getByText('Edit Template')).toBeInTheDocument()
    expect(getByText('Delete Template')).toBeInTheDocument()
  })

  it('calls onEditTemplate when edit button is clicked', () => {
    const {getByText} = renderComponent()

    const editBtn = getByText('Edit Template')
    editBtn.click()

    expect(defaultProps.onEditTemplate).toHaveBeenCalledWith('1')
  })

  it('calls onDeleteTemplate when delete button is clicked', () => {
    const {getByText} = renderComponent()

    const deleteBtn = getByText('Delete Template')
    deleteBtn.click()

    expect(defaultProps.onDeleteTemplate).toHaveBeenCalledWith('1')
  })
})

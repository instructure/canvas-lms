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
import {render, screen} from '@testing-library/react'
import ModuleItemListStudent, {ModuleItemListStudentProps} from '../ModuleItemListStudent'

const defaultProps: ModuleItemListStudentProps = {
  moduleItems: [],
  error: null,
  completionRequirements: [],
}

const buildDefaultProps = (overrides = {}): ModuleItemListStudentProps => {
  return {...defaultProps, ...overrides}
}

const renderComponent = (props: Partial<ModuleItemListStudentProps>) => {
  const componentProps = buildDefaultProps(props)
  return render(<ModuleItemListStudent {...componentProps} />)
}

describe('ModuleItemListStudent', () => {
  it('displays error message when error is present', () => {
    renderComponent({error: {message: 'Failed to load'}})
    expect(screen.getByText('Error loading module items')).toBeInTheDocument()
  })

  it('displays "No items in this module" when moduleItems is empty', () => {
    renderComponent({isEmpty: true})
    expect(screen.getByText('No items in this module')).toBeInTheDocument()
  })
})

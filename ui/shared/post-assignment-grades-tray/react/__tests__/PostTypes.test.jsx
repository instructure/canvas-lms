/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import PostTypes, { EVERYONE, GRADED } from '../PostTypes'

describe('PostTypes', () => {
  let context

  beforeEach(() => {
    context = {
      anonymousGrading: false,
      defaultValue: EVERYONE,
      disabled: false,
      postTypeChanged: jest.fn(),
    }
  })

  it('renders "Everyone" type with description', () => {
    const { getByText } = render(<PostTypes {...context} />)
    expect(getByText('Everyone')).toBeInTheDocument()
    expect(getByText('All students will be able to see their grade and/or submission comments.')).toBeInTheDocument()
  })

  it('renders "Graded" type with description', () => {
    const { getByText } = render(<PostTypes {...context} />)
    expect(getByText('Graded')).toBeInTheDocument()
    expect(getByText('Students who have received a grade or a submission comment will be able to see their grade and/or submission comments.')).toBeInTheDocument()
  })

  it('selects the defaultValue', () => {
    context.defaultValue = GRADED
    const { getByDisplayValue } = render(<PostTypes {...context} />)
    expect(getByDisplayValue('graded')).toBeChecked()
  })

  it('calls postTypeChanged when selecting another type', () => {
    const { getByDisplayValue } = render(<PostTypes {...context} />)
    fireEvent.click(getByDisplayValue('graded'))
    expect(context.postTypeChanged).toHaveBeenCalledTimes(1)
  })

  describe('anonymousGrading prop', () => {
    it('forces EVERYONE type when true', () => {
      context.anonymousGrading = true
      context.defaultValue = GRADED
      const { getByDisplayValue } = render(<PostTypes {...context} />)
      expect(getByDisplayValue('everyone')).toBeChecked()
    })

    it('disables GRADED type when true', () => {
      context.anonymousGrading = true
      const { getByDisplayValue } = render(<PostTypes {...context} />)
      expect(getByDisplayValue('graded')).toBeDisabled()
    })
  })

  describe('"disabled" prop', () => {
    it('enables inputs when false', () => {
      const { getByDisplayValue } = render(<PostTypes {...context} />)
      expect(getByDisplayValue('everyone')).not.toBeDisabled()
      expect(getByDisplayValue('graded')).not.toBeDisabled()
    })

    it('disables inputs when true', () => {
      context.disabled = true
      const { getByDisplayValue } = render(<PostTypes {...context} />)
      expect(getByDisplayValue('everyone')).toBeDisabled()
      expect(getByDisplayValue('graded')).toBeDisabled()
    })
  })
})
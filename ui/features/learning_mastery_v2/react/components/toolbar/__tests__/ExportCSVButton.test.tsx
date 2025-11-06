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
import {ExportCSVButton, ExportCSVButtonProps} from '../ExportCSVButton'

describe('ExportCSVButton', () => {
  const defaultProps = (props = {}): ExportCSVButtonProps => {
    return {
      courseId: '1',
      gradebookFilters: [],
      ...props,
    }
  }

  it('renders the export button correctly on the page', () => {
    const {getByTestId} = render(<ExportCSVButton {...defaultProps()} />)
    expect(getByTestId('export-button')).toBeInTheDocument()
    expect(getByTestId('csv-link')).toBeInTheDocument()
  })

  it('hides csv-link from keyboard navigation and screen readers', () => {
    const {getByTestId} = render(<ExportCSVButton {...defaultProps()} />)
    const csvLink = getByTestId('csv-link')

    expect(csvLink).toHaveAttribute('aria-hidden', 'true')
    expect(csvLink).toHaveAttribute('tabIndex', '-1')
  })
})

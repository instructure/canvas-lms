/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ImageOptionsForm from '../ImageOptionsForm'
import {render, screen} from '@testing-library/react'

describe('ImageOptionsForm', () => {
  it('Show a particular selection of attributes for BlockEditor', () => {
    render(<ImageOptionsForm forBlockEditorUse={true} />)
    expect(screen.getByPlaceholderText('(Describe the image)')).toBeInTheDocument()
    expect(screen.getByLabelText('Decorative Image')).toBeInTheDocument()
    expect(screen.queryByText('Display Options')).not.toBeInTheDocument()
    expect(screen.queryByText('Embed Image')).not.toBeInTheDocument()
    expect(
      screen.queryByLabelText('Display Text Link (Opens in a new tab)'),
    ).not.toBeInTheDocument()
  })

  it('Show a the normal selection of attributes without the block editor prop', () => {
    render(<ImageOptionsForm />)
    expect(screen.getByPlaceholderText('(Describe the image)')).toBeInTheDocument()
    expect(screen.getByLabelText('Decorative Image')).toBeInTheDocument()
    expect(screen.getAllByText('Display Options')[0]).toBeInTheDocument()
    expect(screen.getByText('Embed Image')).toBeInTheDocument()
    expect(screen.getByLabelText('Display Text Link (Opens in a new tab)')).toBeInTheDocument()
  })
})

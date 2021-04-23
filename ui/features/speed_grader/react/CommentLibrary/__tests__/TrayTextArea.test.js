/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import TrayTextArea from '../TrayTextArea'

describe('TrayTextArea', () => {
  it('renders the text area with a placeholder', () => {
    const {getByPlaceholderText} = render(<TrayTextArea />)
    expect(getByPlaceholderText('Write something...')).toBeInTheDocument()
  })

  it('renders a submit button that is initially disabled', () => {
    const {getByText} = render(<TrayTextArea />)
    expect(getByText('Add to Library').closest('button')).toHaveAttribute('disabled')
  })
})

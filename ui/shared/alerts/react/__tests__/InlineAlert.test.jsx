/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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
import CanvasInlineAlert from '../InlineAlert'

describe('CanvasInlineAlert', () => {
  it('renders a basic alert with no sr features', () => {
    const {getByText} = render(<CanvasInlineAlert>alert message</CanvasInlineAlert>)
    expect(getByText('alert message')).toBeInTheDocument()
    expect(document.querySelector('[role="alert"]')).toBeNull()
  })

  it('renders an alert with sr features', () => {
    render(<CanvasInlineAlert liveAlert={true}>alert message</CanvasInlineAlert>)
    expect(document.querySelector('[role="alert"]')).toBeInTheDocument()
  })

  it('renders an sr-only alert', () => {
    render(<CanvasInlineAlert screenReaderOnly={true}>alert message</CanvasInlineAlert>)
    expect(document.querySelector('[role="alert"]')).toBeInTheDocument()
    // There's no great way to tell if instui has done its ScreenReaderContent thing
  })
})

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

import {screen} from '@testing-library/react'
import {HighlightBlock} from '../HighlightBlock'
import {renderBlock} from '../../__tests__/render-helper'

jest.mock('../../../BlockContentEditorContext', () => ({
  __esModule: true,
  useBlockContentEditorContext: jest.fn(() => ({})),
}))

jest.mock('@instructure/canvas-theme', () => ({
  colors: {
    additionalPrimitives: {
      ocean30: '#0374B5',
      ocean12: '#E8F4FD',
    },
    ui: {
      textDescription: '#2D3B45',
    },
  },
}))

describe('HighlightBlock', () => {
  it('should render with Highlight title', () => {
    renderBlock(HighlightBlock, {content: 'Test content'})
    const title = screen.getByText('Highlight')

    expect(title).toBeInTheDocument()
  })

  it('should render the content', () => {
    renderBlock(HighlightBlock, {content: 'Test highlight content'})
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toBeInTheDocument()
    expect(highlightBlock).toHaveTextContent('Test highlight content')
  })
})

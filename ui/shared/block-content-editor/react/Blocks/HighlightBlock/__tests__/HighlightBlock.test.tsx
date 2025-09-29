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

describe('HighlightBlock', () => {
  const defaultProps = {
    content: 'Test content',
    displayIcon: 'warning',
    highlightColor: '#E8F4FD',
    textColor: '#2D3B45',
    backgroundColor: '#E8F4FD',
  }

  it('should render with Highlight title', () => {
    renderBlock(HighlightBlock, {...defaultProps})
    const title = screen.getByText('Highlight')

    expect(title).toBeInTheDocument()
  })

  it('should render the content', () => {
    renderBlock(HighlightBlock, {...defaultProps, content: 'Test highlight content'})
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toBeInTheDocument()
    expect(highlightBlock).toHaveTextContent('Test highlight content')
  })

  it('should display the icon by default', () => {
    renderBlock(HighlightBlock, {...defaultProps})
    const icon = screen.getByTestId('highlight-icon')

    expect(icon).toBeInTheDocument()
  })

  it('should not display the icon when displayIcon is null', () => {
    renderBlock(HighlightBlock, {
      ...defaultProps,
      displayIcon: null,
    })
    const icon = screen.queryByTestId('highlight-icon')

    expect(icon).not.toBeInTheDocument()
  })

  it('should apply the correct highlight color', () => {
    const highlightColor = '#ffeb3b'
    renderBlock(HighlightBlock, {
      ...defaultProps,
      highlightColor,
    })
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toHaveStyle(`background-color: ${highlightColor}`)
  })

  it('should apply default highlight color if none is provided', () => {
    renderBlock(HighlightBlock, {...defaultProps})
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toHaveStyle('background-color: #E8F4FD')
  })

  it('should show placeholder text in edit preview mode when content is empty', () => {
    renderBlock(HighlightBlock, {...defaultProps, content: ''})
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toHaveTextContent('Click to edit')
  })

  it('should use different highlight colors', () => {
    const customHighlightColor = '#FFE4E1'
    renderBlock(HighlightBlock, {
      ...defaultProps,
      content: 'Different background test',
      highlightColor: customHighlightColor,
    })
    const highlightBlock = screen.getByTestId('highlight-block')

    expect(highlightBlock).toHaveStyle(`background-color: ${customHighlightColor}`)
  })
})

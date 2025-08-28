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
import {render} from '@testing-library/react'
import {ImageTextBlockLayout} from '../ImageTextBlockLayout'

describe('ImageTextBlockLayout', () => {
  const testLayout = 'test-layout'
  const titleTestId = 'title'
  const textTestId = 'text'
  const imageTestId = 'image'

  const mockProps = {
    titleComponent: <div data-testid={titleTestId}>Title</div>,
    textComponent: <div data-testid={textTestId}>Text Content</div>,
    imageComponent: <div data-testid={imageTestId}>Image Content</div>,
    includeBlockTitle: true,
    arrangement: 'left' as const,
    textToImageRatio: '1:1' as const,
    dataTestId: testLayout,
  }

  describe('arrangement', () => {
    it('renders image on the left and text on the right when arrangement is "left"', () => {
      const component = render(<ImageTextBlockLayout {...mockProps} arrangement="left" />)

      const flexContainer = component.getByTestId(testLayout)
      const flexItems = flexContainer.children

      expect(flexItems[0]).toContainElement(component.getByTestId(imageTestId))
      expect(flexItems[1]).toContainElement(component.getByTestId(textTestId))
    })

    it('renders image on the right and text on the left when arrangement is "right"', () => {
      const component = render(<ImageTextBlockLayout {...mockProps} arrangement="right" />)

      const flexContainer = component.getByTestId(testLayout)
      const flexItems = flexContainer.children

      expect(flexItems[0]).toContainElement(component.getByTestId(imageTestId))
      expect(flexItems[1]).toContainElement(component.getByTestId(textTestId))
    })
  })

  describe('include title', () => {
    it('renders title when present', () => {
      const component = render(<ImageTextBlockLayout {...mockProps} />)

      expect(component.getByTestId(titleTestId)).toBeInTheDocument()
    })

    it('does not render title when not present', () => {
      const props = {
        ...mockProps,
        titleComponent: null,
      }
      const component = render(<ImageTextBlockLayout {...props} />)

      expect(component.queryByTestId(titleTestId)).not.toBeInTheDocument()
    })
  })

  describe('image size ratio', () => {
    it('applies correct sizes for 1:1 ratio', () => {
      const component = render(<ImageTextBlockLayout {...mockProps} textToImageRatio="1:1" />)

      const flexContainer = component.getByTestId(testLayout)
      const imageItem = flexContainer.children[0]
      const textItem = flexContainer.children[1]

      expect(imageItem).toHaveStyle('flex-basis: 50%')
      expect(textItem).toHaveStyle('flex-basis: 50%')
    })

    it('applies correct sizes for 2:1 ratio', () => {
      const component = render(<ImageTextBlockLayout {...mockProps} textToImageRatio="2:1" />)

      const flexContainer = component.getByTestId(testLayout)
      const imageItem = flexContainer.children[0]
      const textItem = flexContainer.children[1]

      expect(imageItem).toHaveStyle('flex-basis: 33%')
      expect(textItem).toHaveStyle('flex-basis: 67%')
    })
  })
})

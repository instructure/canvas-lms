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

import {Editor, Frame, useNode} from '@craftjs/core'
import {render} from '@testing-library/react'
import React from 'react'
import {IconBlock, type IconBlockProps} from '..'

const mockNode = {
  id: 'test-id',
  data: {
    displayName: IconBlock.craft.displayName,
  },
  events: {
    selected: false,
  },
}

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(() => ({
      node: mockNode,
      connectors: {
        connect: jest.fn(),
        drag: jest.fn(),
      },
    })),
  }
})

const renderIconBlock = (props: Partial<IconBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{IconBlock}}>
      <Frame>
        <IconBlock iconName="idea" data-testid="icon-block" {...props} />
      </Frame>
    </Editor>,
  )
}

describe('IconBlock', () => {
  beforeEach(() => {
    mockNode.events.selected = false
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders with default props', () => {
      const {getByTestId} = renderIconBlock()
      const iconBlock = getByTestId('icon-block')
      const icon = iconBlock.querySelector('svg')

      expect(iconBlock).toBeInTheDocument()
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('class', expect.stringContaining('inlineSVG-svgIcon'))
    })

    it('renders with custom size', () => {
      const {getByTestId} = renderIconBlock({size: 'large'})
      const icon = getByTestId('icon-block').querySelector('svg')

      expect(icon).toHaveAttribute('class', expect.stringContaining('inlineSVG-svgIcon'))
    })

    it('renders with custom color', () => {
      const {getByTestId} = renderIconBlock({color: 'rgb(255, 0, 0)'})
      const iconBlock = getByTestId('icon-block')

      expect(iconBlock).toHaveStyle({
        color: 'rgb(255, 0, 0)',
      })
    })
  })

  describe('accessibility', () => {
    it('sets correct aria attributes', () => {
      const {getByTestId} = renderIconBlock()
      const iconBlock = getByTestId('icon-block')

      expect(iconBlock).toHaveAttribute('role', 'treeitem')
      expect(iconBlock).toHaveAttribute('aria-label', IconBlock.craft.displayName)
      expect(iconBlock).toHaveAttribute('aria-selected', 'false')
      expect(iconBlock).toHaveAttribute('tabIndex', '-1')
    })

    it('reflects selection state', () => {
      mockNode.events.selected = true
      const {getByTestId} = renderIconBlock()
      const iconBlock = getByTestId('icon-block')

      expect(iconBlock).toHaveAttribute('aria-selected', 'true')
    })
  })
})

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

import {Editor, Frame} from '@craftjs/core'
import {render} from '@testing-library/react'
import React from 'react'
import {Container, type ContainerProps} from '..'

const mockNode = {
  id: 'xyzzy',
  data: {
    displayName: Container.craft.displayName,
    custom: {
      isExpanded: false,
    },
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

const renderContainer = (props: Partial<ContainerProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{Container}}>
      <Frame>
        <Container {...props} />
      </Frame>
    </Editor>,
  )
}

describe('Container', () => {
  beforeEach(() => {
    mockNode.events.selected = false
    mockNode.data.custom.isExpanded = false
  })

  it('renders with default props', () => {
    const {getByTestId} = renderContainer()
    const container = getByTestId('container-block')
    expect(container).toBeInTheDocument()
    expect(container).toHaveAttribute('data-placeholder', 'Drop blocks here')
    expect(container).toHaveAttribute('id', 'container-xyzzy')
    expect(container).toHaveClass('container-block')
  })

  it('renders with custom id', () => {
    const {getByTestId} = renderContainer({id: 'custom-id'})
    const container = getByTestId('container-block')
    expect(container).toHaveAttribute('id', 'custom-id')
  })

  it('renders with custom background color', () => {
    const {getByTestId} = renderContainer({background: 'rgb(0, 0, 255)'})
    const container = getByTestId('container-block')
    expect(container).toHaveStyle({backgroundColor: 'rgb(0, 0, 255)'})
  })

  it('renders with custom styles', () => {
    const {getByTestId} = renderContainer({style: {color: 'rgb(255, 0, 0)'}})
    const container = getByTestId('container-block')
    expect(container).toHaveStyle({color: 'rgb(255, 0, 0)'})
  })

  it('renders with custom placeholder', () => {
    const {getByTestId} = renderContainer({'data-placeholder': 'Custom placeholder'})
    const container = getByTestId('container-block')
    expect(container).toHaveAttribute('data-placeholder', 'Custom placeholder')
  })

  it('renders with custom class names', () => {
    const {getByTestId} = renderContainer({className: 'custom-class'})
    const container = getByTestId('container-block')
    expect(container).toHaveClass('custom-class')
    expect(container).toHaveClass('container-block')
  })

  it('renders children', () => {
    const {getByText} = renderContainer({children: <div>Child content</div>})
    expect(getByText('Child content')).toBeInTheDocument()
  })

  describe('accessibility attributes', () => {
    it('sets correct aria attributes', () => {
      const {getByTestId} = renderContainer()
      const container = getByTestId('container-block')
      expect(container).toHaveAttribute('aria-label', Container.craft.displayName)
      expect(container).toHaveAttribute('aria-selected', 'false')
      expect(container).toHaveAttribute('aria-expanded', 'false')
      expect(container).toHaveAttribute('role', 'treeitem')
    })

    it('reflects selection state', () => {
      mockNode.events.selected = true
      const {getByTestId} = renderContainer()
      const container = getByTestId('container-block')
      expect(container).toHaveAttribute('aria-selected', 'true')
    })

    it('reflects expansion state', () => {
      mockNode.data.custom.isExpanded = true
      const {getByTestId} = renderContainer()
      const container = getByTestId('container-block')
      expect(container).toHaveAttribute('aria-expanded', 'true')
    })
  })
})

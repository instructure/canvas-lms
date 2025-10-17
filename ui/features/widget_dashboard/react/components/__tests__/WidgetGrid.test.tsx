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
import WidgetGrid from '../WidgetGrid'
import type {WidgetConfig} from '../../types'

// Mock the WidgetRegistry to avoid dependency issues
jest.mock('../WidgetRegistry', () => ({
  getWidget: jest.fn(() => ({
    component: ({widget}: any) => <div data-testid={`widget-${widget.id}`}>{widget.title}</div>,
    displayName: 'Mock Widget',
    description: 'Mock widget for testing',
  })),
}))

type Props = {
  config: WidgetConfig
}

const setUp = (props: Props) => {
  return render(<WidgetGrid {...props} />)
}

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {
    config: {
      columns: 2,
      widgets: [
        {
          id: 'widget-1',
          type: 'test-widget',
          position: {col: 1, row: 1, relative: 1},
          title: 'Widget 1',
        },
        {
          id: 'widget-2',
          type: 'test-widget',
          position: {col: 2, row: 1, relative: 2},
          title: 'Widget 2',
        },
        {
          id: 'widget-3',
          type: 'test-widget',
          position: {col: 1, row: 2, relative: 3},
          title: 'Widget 3',
        },
      ],
    },
  }

  return {
    ...defaultProps,
    ...overrides,
    config: {
      ...defaultProps.config,
      ...(overrides as any)?.config,
    },
  }
}

const indexInParent = (el: HTMLElement) => Array.from(el.parentNode!.children).indexOf(el)

// Mock window.matchMedia for responsive testing
const mockMatchMedia = (width: number) => {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation((query: string) => {
      let matches = false

      // Mobile: maxWidth: '639px'
      if (query.includes('max-width: 639px')) {
        matches = width <= 639
      }
      // Tablet: minWidth: '640px', maxWidth: '1023px'
      else if (query.includes('min-width: 640px') && query.includes('max-width: 1023px')) {
        matches = width >= 640 && width <= 1023
      }
      // Desktop: minWidth: '1024px'
      else if (query.includes('min-width: 1024px')) {
        matches = width >= 1024
      }

      return {
        matches,
        media: query,
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        dispatchEvent: jest.fn(),
      }
    }),
  })
}

describe('WidgetGrid', () => {
  beforeEach(() => {
    // Default to desktop view
    mockMatchMedia(1200)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('Desktop Layout (≥1024px)', () => {
    beforeEach(() => {
      mockMatchMedia(1200)
    })

    it('positions widgets in the correct column and row', () => {
      const {getByTestId} = setUp(buildDefaultProps())

      // Widget 1: col 1, row 1
      const widget1Container = getByTestId('widget-container-widget-1')
      expect(indexInParent(widget1Container)).toBe(0) // row 1
      // With Flex components, we need to go up an extra level: widget-container -> inner Flex -> Flex.Item (column)
      expect(indexInParent(widget1Container.parentNode!.parentNode as HTMLElement)).toBe(0) // column 1

      // Widget 2: col 2, row 1
      const widget2Container = getByTestId('widget-container-widget-2')
      expect(indexInParent(widget2Container)).toBe(0) // row 1
      expect(indexInParent(widget2Container.parentNode!.parentNode as HTMLElement)).toBe(1) // column 2

      // Widget 3: col 1, row 2
      const widget3Container = getByTestId('widget-container-widget-3')
      expect(indexInParent(widget3Container)).toBe(1) // row 2
      expect(indexInParent(widget3Container.parentNode!.parentNode as HTMLElement)).toBe(0) // column 1
    })
  })

  describe('Tablet Layout (640-1023px)', () => {
    beforeEach(() => {
      mockMatchMedia(800)
    })

    it('renders single column layout', () => {
      const {getByTestId} = setUp(buildDefaultProps())
      const grid = getByTestId('widget-columns')

      expect(grid).toBeInTheDocument()
      expect(grid).toHaveStyle({
        display: 'flex',
      })
      expect(grid.childElementCount).toBe(1)
    })

    it('sorts widgets in proper stacking order (relative)', () => {
      const {getAllByTestId} = setUp(buildDefaultProps())
      const widgetContainers = getAllByTestId(/^widget-container-/)

      // Expected order: widget-1 (relative 1), widget-2 (relative 2), widget-3 (relative 3)
      expect(widgetContainers[0]).toHaveAttribute('data-testid', 'widget-container-widget-1')
      expect(widgetContainers[1]).toHaveAttribute('data-testid', 'widget-container-widget-2')
      expect(widgetContainers[2]).toHaveAttribute('data-testid', 'widget-container-widget-3')
    })
  })

  describe('Empty Configuration', () => {
    it('handles empty widget configuration gracefully', () => {
      const config: WidgetConfig = {
        columns: 3,
        widgets: [],
      }

      const {getByTestId} = setUp({config})
      const columns = getByTestId('widget-columns')

      expect(columns).toBeInTheDocument()
      expect(columns.children).toHaveLength(2)
      expect((columns.children.item(0) as Element).children).toHaveLength(0)
      expect((columns.children.item(1) as Element).children).toHaveLength(0)
    })
  })

  describe('Widget Rendering', () => {
    it('renders all widgets with proper test IDs', () => {
      const {getByTestId} = setUp(buildDefaultProps())

      expect(getByTestId('widget-widget-1')).toBeInTheDocument()
      expect(getByTestId('widget-widget-2')).toBeInTheDocument()
      expect(getByTestId('widget-widget-3')).toBeInTheDocument()
    })

    it('renders widget content correctly', () => {
      const {getByTestId} = setUp(buildDefaultProps())

      expect(getByTestId('widget-widget-1')).toHaveTextContent('Widget 1')
      expect(getByTestId('widget-widget-2')).toHaveTextContent('Widget 2')
      expect(getByTestId('widget-widget-3')).toHaveTextContent('Widget 3')
    })
  })
})

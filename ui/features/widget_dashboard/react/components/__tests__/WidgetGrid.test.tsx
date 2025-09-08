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
      columns: 3,
      widgets: [
        {
          id: 'widget-1',
          type: 'test-widget',
          position: {col: 1, row: 1},
          size: {width: 1, height: 1},
          title: 'Widget 1',
        },
        {
          id: 'widget-2',
          type: 'test-widget',
          position: {col: 2, row: 1},
          size: {width: 1, height: 1},
          title: 'Widget 2',
        },
        {
          id: 'widget-3',
          type: 'test-widget',
          position: {col: 1, row: 2},
          size: {width: 2, height: 1},
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

    it('renders desktop grid layout with proper CSS grid properties', () => {
      const {getByTestId} = setUp(buildDefaultProps())
      const grid = getByTestId('widget-grid')

      expect(grid).toBeInTheDocument()
      expect(grid).toHaveStyle({
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: '1rem',
      })
    })

    it('positions widgets using explicit grid coordinates', () => {
      const {getByTestId} = setUp(buildDefaultProps())

      // Widget 1: col 1, row 1, width 1, height 1 -> gridColumn: "1 / 2", gridRow: "1 / 2"
      const widget1Container = getByTestId('widget-container-widget-1')
      expect(widget1Container).toHaveStyle({
        gridColumn: '1 / 2',
        gridRow: '1 / 2',
      })

      // Widget 2: col 2, row 1, width 1, height 1 -> gridColumn: "2 / 3", gridRow: "1 / 2"
      const widget2Container = getByTestId('widget-container-widget-2')
      expect(widget2Container).toHaveStyle({
        gridColumn: '2 / 3',
        gridRow: '1 / 2',
      })

      // Widget 3: col 1, row 2, width 2, height 1 -> gridColumn: "1 / 3", gridRow: "2 / 3"
      const widget3Container = getByTestId('widget-container-widget-3')
      expect(widget3Container).toHaveStyle({
        gridColumn: '1 / 3',
        gridRow: '2 / 3',
      })
    })

    it('calculates correct number of rows based on widget positions', () => {
      const {getByTestId} = setUp(buildDefaultProps())
      const grid = getByTestId('widget-grid')

      // Max row is 2 (widget-3), so gridTemplateRows should be "repeat(2, 20rem)"
      expect(grid).toHaveStyle({
        gridTemplateRows: 'repeat(2, 20rem)',
      })
    })
  })

  describe('Tablet Layout (640-1023px)', () => {
    beforeEach(() => {
      mockMatchMedia(800)
    })

    it('renders tablet stacked layout with flexbox and double width', () => {
      const {getByTestId} = setUp(buildDefaultProps())
      const grid = getByTestId('widget-grid')

      expect(grid).toBeInTheDocument()
      expect(grid).toHaveStyle({
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem',
        maxWidth: '800px',
        margin: '0 auto',
      })
    })

    it('does not use explicit grid positioning on tablet', () => {
      const {getByTestId} = setUp(buildDefaultProps())

      // In tablet view, widgets should not have gridColumn/gridRow styles
      const widget1Container = getByTestId('widget-container-widget-1')
      const containerStyle = window.getComputedStyle(widget1Container)
      expect(containerStyle.gridColumn).toBe('')
      expect(containerStyle.gridRow).toBe('')
    })

    it('sorts widgets in proper stacking order (row then column)', () => {
      const {getAllByTestId} = setUp(buildDefaultProps())
      const widgetContainers = getAllByTestId(/^widget-container-/)

      // Expected order: widget-1 (row 1, col 1), widget-2 (row 1, col 2), widget-3 (row 2, col 1)
      expect(widgetContainers[0]).toHaveAttribute('data-testid', 'widget-container-widget-1')
      expect(widgetContainers[1]).toHaveAttribute('data-testid', 'widget-container-widget-2')
      expect(widgetContainers[2]).toHaveAttribute('data-testid', 'widget-container-widget-3')
    })
  })

  describe('Mobile Layout (≤639px)', () => {
    beforeEach(() => {
      mockMatchMedia(400)
    })

    it('renders mobile flexbox layout with vertical stacking', () => {
      const {getByTestId} = setUp(buildDefaultProps())
      const grid = getByTestId('widget-grid')

      expect(grid).toBeInTheDocument()
      expect(grid).toHaveStyle({
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem',
      })
    })

    it('sorts widgets in proper stacking order for mobile', () => {
      const {getAllByTestId} = setUp(buildDefaultProps())
      const widgetContainers = getAllByTestId(/^widget-container-/)

      // Expected order: widget-1 (row 1, col 1), widget-2 (row 1, col 2), widget-3 (row 2, col 1)
      expect(widgetContainers[0]).toHaveAttribute('data-testid', 'widget-container-widget-1')
      expect(widgetContainers[1]).toHaveAttribute('data-testid', 'widget-container-widget-2')
      expect(widgetContainers[2]).toHaveAttribute('data-testid', 'widget-container-widget-3')
    })
  })

  describe('Widget Sorting Utility', () => {
    it('sorts widgets by row first, then by column', () => {
      const config: WidgetConfig = {
        columns: 3,
        widgets: [
          {
            id: 'widget-a',
            type: 'test-widget',
            position: {col: 2, row: 2},
            size: {width: 1, height: 1},
            title: 'Widget A',
          },
          {
            id: 'widget-b',
            type: 'test-widget',
            position: {col: 1, row: 1},
            size: {width: 1, height: 1},
            title: 'Widget B',
          },
          {
            id: 'widget-c',
            type: 'test-widget',
            position: {col: 3, row: 1},
            size: {width: 1, height: 1},
            title: 'Widget C',
          },
          {
            id: 'widget-d',
            type: 'test-widget',
            position: {col: 1, row: 2},
            size: {width: 1, height: 1},
            title: 'Widget D',
          },
        ],
      }

      // Test with mobile layout to verify sorting
      mockMatchMedia(400)
      const {getAllByTestId} = setUp({config})
      const widgetContainers = getAllByTestId(/^widget-container-/)

      // Expected order: widget-b (1,1), widget-c (3,1), widget-d (1,2), widget-a (2,2)
      expect(widgetContainers[0]).toHaveAttribute('data-testid', 'widget-container-widget-b')
      expect(widgetContainers[1]).toHaveAttribute('data-testid', 'widget-container-widget-c')
      expect(widgetContainers[2]).toHaveAttribute('data-testid', 'widget-container-widget-d')
      expect(widgetContainers[3]).toHaveAttribute('data-testid', 'widget-container-widget-a')
    })
  })

  describe('Empty Configuration', () => {
    it('handles empty widget configuration gracefully', () => {
      const config: WidgetConfig = {
        columns: 3,
        widgets: [],
      }

      const {getByTestId} = setUp({config})
      const grid = getByTestId('widget-grid')

      expect(grid).toBeInTheDocument()
      expect(grid.children).toHaveLength(0)
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

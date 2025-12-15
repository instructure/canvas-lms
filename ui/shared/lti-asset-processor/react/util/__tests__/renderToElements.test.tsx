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
import {z} from 'zod'
import {renderToElements, renderAPComponent, renderAPComponentNoQC} from '../renderToElements'

// Mock only what's actually used
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(),
}))

vi.mock('react-dom/client', () => ({
  createRoot: vi.fn(),
}))

vi.mock('@canvas/query', () => ({
  queryClient: {},
}))

vi.mock('@canvas/i18n', () => ({
  useScope: vi.fn(() => ({
    t: vi.fn((key: string) => key),
  })),
}))

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {createRoot} from 'react-dom/client'

const mockShowFlashError = showFlashError as ReturnType<typeof vi.fn>
const mockCreateRoot = createRoot as ReturnType<typeof vi.fn>

describe('renderToElements', () => {
  let mockRender: ReturnType<typeof vi.fn>
  let mockRoot: any

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = ''

    // Reset mocks
    vi.clearAllMocks()

    // Setup mock root
    mockRender = vi.fn()
    mockRoot = {render: mockRender}
    mockCreateRoot.mockReturnValue(mockRoot)

    // Mock console methods
    vi.spyOn(console, 'warn').mockImplementation(() => {})
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('basic functionality', () => {
    const TestComponent = () => <div>Test Component</div>

    it('renders component to matching divs without schema', () => {
      document.body.innerHTML = `
        <div class="test-component"></div>
        <div class="test-component"></div>
        <div class="other-component"></div>
      `

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(2)
      expect(mockCreateRoot).toHaveBeenCalledTimes(2)
      expect(mockRender).toHaveBeenCalledTimes(2)
      expect(mockShowFlashError).not.toHaveBeenCalled()
    })

    it('returns 0 when no divs match selector', () => {
      document.body.innerHTML = '<div class="other-component"></div>'

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(0)
      expect(mockCreateRoot).not.toHaveBeenCalled()
      expect(mockRender).not.toHaveBeenCalled()
      expect(mockShowFlashError).not.toHaveBeenCalled()
    })
  })

  describe('with zod schema', () => {
    const schema = z.object({
      userId: z.string(),
      isActive: z.string().transform(val => val === 'true'),
    })

    const TestComponent = ({userId, isActive}: {userId: string; isActive: boolean}) => (
      <div>
        User: {userId}, Active: {isActive ? 'Yes' : 'No'}
      </div>
    )

    it('renders component with valid dataset', () => {
      const div = document.createElement('div')
      div.className = 'test-component'
      div.dataset.userId = '123'
      div.dataset.isActive = 'true'
      document.body.appendChild(div)

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: schema,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
      expect(mockRender).toHaveBeenCalledTimes(1)
      expect(mockShowFlashError).not.toHaveBeenCalled()
    })

    it('skips rendering with invalid dataset', () => {
      const div = document.createElement('div')
      div.className = 'test-component'
      div.dataset.invalidProp = 'invalid'
      document.body.appendChild(div)

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: schema,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(0)
      expect(mockCreateRoot).not.toHaveBeenCalled()
      expect(mockRender).not.toHaveBeenCalled()
      expect(console.warn).toHaveBeenCalledWith(
        'Invalid props for element .test-component:',
        expect.any(Object),
      )
      expect(mockShowFlashError).toHaveBeenCalledWith('Test Error')
    })

    it('handles mixed valid and invalid datasets', () => {
      // Valid div
      const validDiv = document.createElement('div')
      validDiv.className = 'test-component'
      validDiv.dataset.userId = '123'
      validDiv.dataset.isActive = 'true'
      document.body.appendChild(validDiv)

      // Invalid div
      const invalidDiv = document.createElement('div')
      invalidDiv.className = 'test-component'
      invalidDiv.dataset.invalidProp = 'invalid'
      document.body.appendChild(invalidDiv)

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: schema,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
      expect(mockRender).toHaveBeenCalledTimes(1)
      expect(mockShowFlashError).toHaveBeenCalledWith('Test Error')
    })
  })

  describe('QueryClient wrapping', () => {
    const TestComponent = () => <div>Test Component</div>

    it('wraps component with QueryClientProvider when withQueryClient is true', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: true,
      })

      expect(mockRender).toHaveBeenCalledTimes(1)
      // Check that the rendered element includes QueryClientProvider
      const renderedElement = mockRender.mock.calls[0][0]
      expect(renderedElement.props.children.type.name).toBe('QueryClientProvider')
    })

    it('does not wrap component when withQueryClient is false', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(mockRender).toHaveBeenCalledTimes(1)
      // Check that the rendered element is the component directly (wrapped in error boundary)
      const renderedElement = mockRender.mock.calls[0][0]
      expect(renderedElement.props.children.type).toBe(TestComponent)
    })
  })

  describe('error handling', () => {
    const TestComponent = () => <div>Test Component</div>

    it('shows flash error when createRoot throws', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      mockCreateRoot.mockImplementationOnce(() => {
        throw new Error('createRoot failed')
      })

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(0)
      expect(console.error).toHaveBeenCalledWith(
        'Error rendering element .test-component',
        expect.any(Error),
      )
      expect(mockShowFlashError).toHaveBeenCalledWith('Test Error')
    })

    it('shows flash error when render throws', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      mockRender.mockImplementationOnce(() => {
        throw new Error('render failed')
      })

      const count = renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(count).toBe(0)
      expect(console.error).toHaveBeenCalledWith(
        'Error rendering element .test-component',
        expect.any(Error),
      )
      expect(mockShowFlashError).toHaveBeenCalledWith('Test Error')
    })
  })

  describe('selector handling', () => {
    const TestComponent = () => <div>Test Component</div>

    it('correctly formats selector with div prefix', () => {
      document.body.innerHTML = '<div class="test-component"></div>'
      vi.spyOn(document, 'querySelectorAll')

      renderToElements({
        selector: '.test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(document.querySelectorAll).toHaveBeenCalledWith('.test-component')
    })

    it('works with ID selectors', () => {
      document.body.innerHTML = '<div id="test-component"></div>'
      vi.spyOn(document, 'querySelectorAll')

      renderToElements({
        selector: '#test-component',
        Component: TestComponent,
        datasetSchema: undefined,
        flashErrorTitle: 'Test Error',
        withQueryClient: false,
      })

      expect(document.querySelectorAll).toHaveBeenCalledWith('#test-component')
    })
  })
})

describe('convenience functions', () => {
  const TestComponent = () => <div>Test Component</div>

  beforeEach(() => {
    document.body.innerHTML = ''
    vi.clearAllMocks()

    const mockRender = vi.fn()
    const mockRoot = {render: mockRender}
    mockCreateRoot.mockReturnValue(mockRoot as any)
  })

  describe('renderAPComponent', () => {
    it('renders with QueryClient enabled', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      const count = renderAPComponent('.test-component', TestComponent)

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
    })

    it('works with schema', () => {
      const schema = z.object({userId: z.string()})
      const div = document.createElement('div')
      div.className = 'test-component'
      div.dataset.userId = '123'
      document.body.appendChild(div)

      const count = renderAPComponent('.test-component', TestComponent, schema)

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
    })
  })

  describe('renderAPComponentNoQC', () => {
    it('renders without QueryClient', () => {
      document.body.innerHTML = '<div class="test-component"></div>'

      const count = renderAPComponentNoQC('.test-component', TestComponent)

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
    })

    it('works with schema', () => {
      const schema = z.object({userId: z.string()})
      const div = document.createElement('div')
      div.className = 'test-component'
      div.dataset.userId = '123'
      document.body.appendChild(div)

      const count = renderAPComponentNoQC('.test-component', TestComponent, schema)

      expect(count).toBe(1)
      expect(mockCreateRoot).toHaveBeenCalledTimes(1)
    })
  })
})

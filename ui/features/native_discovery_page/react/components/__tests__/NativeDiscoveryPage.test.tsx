/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import {NativeDiscoveryPage} from '../NativeDiscoveryPage'

describe('NativeDiscoveryPage', () => {
  const defaultProps = {
    initialEnabled: false,
    onChange: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('rendering', () => {
    it('renders the component with all expected elements', () => {
      const {getByText, getAllByText, getByTestId} = render(
        <NativeDiscoveryPage {...defaultProps} />,
      )
      expect(getByText('Configure')).toBeInTheDocument()
      expect(getAllByText('Enable Identity Service Discovery Page')).toHaveLength(2)
      expect(getByTestId('discovery-page-toggle')).toBeInTheDocument()
    })

    it('renders with checkbox unchecked when initialEnabled is false', () => {
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} initialEnabled={false} />)
      const checkbox = getByTestId('discovery-page-toggle')
      expect(checkbox).not.toBeChecked()
    })

    it('renders with checkbox checked when initialEnabled is true', () => {
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} initialEnabled={true} />)
      const checkbox = getByTestId('discovery-page-toggle')
      expect(checkbox).toBeChecked()
    })

    it('renders screen reader content for accessibility', () => {
      const {getByText} = render(<NativeDiscoveryPage {...defaultProps} />)
      const srContent = getByText('Enable Identity Service Discovery Page', {
        selector: '[class*="screenReaderContent"]',
      })
      expect(srContent).toBeInTheDocument()
    })
  })

  describe('toggle functionality', () => {
    it('calls onChange with true when toggling from false to true', () => {
      const onChange = vi.fn()
      const {getByTestId} = render(
        <NativeDiscoveryPage initialEnabled={false} onChange={onChange} />,
      )
      const checkbox = getByTestId('discovery-page-toggle')
      fireEvent.click(checkbox)
      expect(onChange).toHaveBeenCalledTimes(1)
      expect(onChange).toHaveBeenCalledWith(true)
    })

    it('calls onChange with false when toggling from true to false', () => {
      const onChange = vi.fn()
      const {getByTestId} = render(
        <NativeDiscoveryPage initialEnabled={true} onChange={onChange} />,
      )
      const checkbox = getByTestId('discovery-page-toggle')
      fireEvent.click(checkbox)
      expect(onChange).toHaveBeenCalledTimes(1)
      expect(onChange).toHaveBeenCalledWith(false)
    })

    it('updates the checkbox state when toggled', () => {
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} initialEnabled={false} />)
      const checkbox = getByTestId('discovery-page-toggle')
      expect(checkbox).not.toBeChecked()
      fireEvent.click(checkbox)
      expect(checkbox).toBeChecked()
      fireEvent.click(checkbox)
      expect(checkbox).not.toBeChecked()
    })

    it('handles multiple toggle events correctly', () => {
      const onChange = vi.fn()
      const {getByTestId} = render(
        <NativeDiscoveryPage initialEnabled={false} onChange={onChange} />,
      )
      const checkbox = getByTestId('discovery-page-toggle')
      fireEvent.click(checkbox)
      expect(onChange).toHaveBeenNthCalledWith(1, true)
      fireEvent.click(checkbox)
      expect(onChange).toHaveBeenNthCalledWith(2, false)
      fireEvent.click(checkbox)
      expect(onChange).toHaveBeenNthCalledWith(3, true)
      expect(onChange).toHaveBeenCalledTimes(3)
    })
  })

  describe('configure button', () => {
    it('shows an alert when configure button is clicked', () => {
      const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} />)
      const configureButton = getByTestId('configure-button')
      fireEvent.click(configureButton)
      expect(alertSpy).toHaveBeenCalledTimes(1)
      expect(alertSpy).toHaveBeenCalledWith(
        'Configuration modal will be implemented in future work',
      )
    })

    it('does not call onChange when configure button is clicked', () => {
      const onChange = vi.fn()
      vi.spyOn(window, 'alert').mockImplementation(() => {})
      const {getByTestId} = render(
        <NativeDiscoveryPage initialEnabled={false} onChange={onChange} />,
      )
      const configureButton = getByTestId('configure-button')
      fireEvent.click(configureButton)
      expect(onChange).not.toHaveBeenCalled()
    })
  })

  describe('accessibility', () => {
    it('has accessible button for configure', () => {
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} />)
      const button = getByTestId('configure-button')
      expect(button).toBeInTheDocument()
      expect(button.textContent).toBe('Configure')
    })

    it('has properly labeled checkbox', () => {
      const {getByLabelText} = render(<NativeDiscoveryPage {...defaultProps} />)
      const checkbox = getByLabelText('Enable Identity Service Discovery Page')
      expect(checkbox).toBeInTheDocument()
      expect(checkbox).toHaveAttribute('type', 'checkbox')
    })

    it('checkbox has toggle variant', () => {
      const {container} = render(<NativeDiscoveryPage {...defaultProps} />)
      // InstUI toggle checkboxes have toggle-specific classes
      const toggleFacade = container.querySelector('[class*="toggleFacade"]')
      expect(toggleFacade).toBeInTheDocument()
    })
  })

  describe('component structure', () => {
    it('renders configure button and checkbox in correct order', () => {
      const {container} = render(<NativeDiscoveryPage {...defaultProps} />)
      const flexItems = container.querySelectorAll('[class*="flexItem"]')
      expect(flexItems.length).toBeGreaterThanOrEqual(2)
      // configure button should be first
      const firstItem = flexItems[0]
      expect(firstItem.textContent).toContain('Configure')
      // checkbox should be second
      const secondItem = flexItems[1]
      expect(secondItem.textContent).toContain('Enable Identity Service Discovery Page')
    })

    it('uses Flex layout with correct alignment', () => {
      const {container} = render(<NativeDiscoveryPage {...defaultProps} />)
      const flexContainer = container.querySelector('[class*="flex"]')
      expect(flexContainer).toBeInTheDocument()
    })

    it('wraps component in View with test id', () => {
      const {getByTestId} = render(<NativeDiscoveryPage {...defaultProps} />)
      expect(getByTestId('native-discovery-page')).toBeInTheDocument()
    })
  })
})

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
import {renderComponent} from '../../../__tests__/renderingShims'
import {describe, expect, it} from '../../../__tests__/testPlatformShims'
import {ToolIconOrDefault} from '../ToolIconOrDefault'

describe('ToolIconOrDefault', () => {
  const defaultProps = {
    toolId: '12345',
    toolName: 'Test Tool',
    size: 24,
  }

  describe('alt text behavior', () => {
    it('uses tool name as alt text by default', () => {
      renderComponent(
        <ToolIconOrDefault {...defaultProps} iconUrl="https://example.com/icon.png" />,
      )
      const img = screen.getByAltText('Test Tool')
      expect(img).toBeInTheDocument()
    })

    it('uses tool name as alt text when decorative is false', () => {
      renderComponent(
        <ToolIconOrDefault
          {...defaultProps}
          iconUrl="https://example.com/icon.png"
          decorative={false}
        />,
      )
      const img = screen.getByAltText('Test Tool')
      expect(img).toBeInTheDocument()
    })

    it('uses empty alt text when decorative is true', () => {
      const {container} = renderComponent(
        <ToolIconOrDefault
          {...defaultProps}
          iconUrl="https://example.com/icon.png"
          decorative={true}
        />,
      )
      const img = container.querySelector('img')
      expect(img).toHaveAttribute('alt', '')
    })

    it('uses empty alt text for default icon when decorative is true', () => {
      const {container} = renderComponent(
        <ToolIconOrDefault {...defaultProps} iconUrl={null} decorative={true} />,
      )
      const img = container.querySelector('img')
      expect(img).toHaveAttribute('alt', '')
    })

    it('uses tool name for default icon when decorative is false', () => {
      renderComponent(<ToolIconOrDefault {...defaultProps} iconUrl={null} decorative={false} />)
      const img = screen.getByAltText('Test Tool')
      expect(img).toBeInTheDocument()
    })
  })

  describe('icon rendering', () => {
    it('renders custom icon when iconUrl is provided', () => {
      const {container} = renderComponent(
        <ToolIconOrDefault {...defaultProps} iconUrl="https://example.com/icon.png" />,
      )
      const img = container.querySelector('img')
      expect(img).toHaveAttribute('src', 'https://example.com/icon.png')
    })

    it('renders default icon when iconUrl is null', () => {
      const {container} = renderComponent(<ToolIconOrDefault {...defaultProps} iconUrl={null} />)
      const img = container.querySelector('img')
      expect(img).toHaveAttribute('src', '/lti/tool_default_icon?id=12345&name=Test%20Tool')
    })

    it('applies custom size', () => {
      const {container} = renderComponent(
        <ToolIconOrDefault {...defaultProps} iconUrl={null} size={48} />,
      )
      const img = container.querySelector('img')
      expect(img).toHaveStyle({height: 48, width: 48})
    })
  })
})

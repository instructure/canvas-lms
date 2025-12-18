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

import {render, screen, fireEvent} from '@testing-library/react'
import {ButtonBlockGeneralButtonSettings} from '../ButtonBlockGeneralButtonSettings'
import {ButtonBlockGeneralButtonSettingsProps} from '../types'

const defaultProps: ButtonBlockGeneralButtonSettingsProps = {
  alignment: 'left',
  layout: 'horizontal',
  isFullWidth: false,
  onAlignmentChange: vi.fn(),
  onLayoutChange: vi.fn(),
  onIsFullWidthChange: vi.fn(),
}

describe('ButtonBlockGeneralButtonSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders all alignment options', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} />)

      expect(screen.getByText('Alignment')).toBeInTheDocument()
      expect(screen.getByLabelText('Left aligned')).toBeInTheDocument()
      expect(screen.getByLabelText('Middle aligned')).toBeInTheDocument()
      expect(screen.getByLabelText('Right aligned')).toBeInTheDocument()
    })

    it('renders all layout options', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} />)

      expect(screen.getByText('Button layout')).toBeInTheDocument()
      expect(screen.getByLabelText('Horizontal')).toBeInTheDocument()
      expect(screen.getByLabelText('Vertical')).toBeInTheDocument()
    })

    it('renders full width checkbox', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} />)

      expect(screen.getByLabelText('Full width buttons')).toBeInTheDocument()
    })

    it('does not render alignment options when isFullWidth is true', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} isFullWidth={true} />)

      expect(screen.queryByText('Alignment')).not.toBeInTheDocument()
    })
  })

  describe('state selection', () => {
    it('selects the correct alignment option', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} alignment={'center'} />)

      expect(screen.getByLabelText('Middle aligned')).toBeChecked()
      expect(screen.getByLabelText('Left aligned')).not.toBeChecked()
      expect(screen.getByLabelText('Right aligned')).not.toBeChecked()
    })

    it('selects the correct layout option', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} layout="vertical" />)

      expect(screen.getByLabelText('Vertical')).toBeChecked()
      expect(screen.getByLabelText('Horizontal')).not.toBeChecked()
    })

    it('shows full width checkbox as checked when isFullWidth is true', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} isFullWidth={true} />)

      expect(screen.getByLabelText('Full width buttons')).toBeChecked()
    })
  })

  describe('event handlers', () => {
    it('calls onAlignmentChange when alignment option is selected', () => {
      const onAlignmentChange = vi.fn()
      render(
        <ButtonBlockGeneralButtonSettings
          {...defaultProps}
          onAlignmentChange={onAlignmentChange}
        />,
      )

      fireEvent.click(screen.getByLabelText('Right aligned'))

      expect(onAlignmentChange).toHaveBeenCalledWith('right')
    })

    it('calls onLayoutChange when layout option is selected', () => {
      const onLayoutChange = vi.fn()
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} onLayoutChange={onLayoutChange} />)

      fireEvent.click(screen.getByLabelText('Vertical'))

      expect(onLayoutChange).toHaveBeenCalledWith('vertical')
    })

    it('calls onIsFullWidthChange when checkbox is changed', () => {
      const onIsFullWidthChange = vi.fn()
      render(
        <ButtonBlockGeneralButtonSettings
          {...defaultProps}
          onIsFullWidthChange={onIsFullWidthChange}
        />,
      )

      fireEvent.click(screen.getByLabelText('Full width buttons'))

      expect(onIsFullWidthChange).toHaveBeenCalledWith(true)
    })
  })
})

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
import {
  ButtonBlockGeneralButtonSettings,
  ButtonBlockGeneralButtonSettingsProps,
} from '../ButtonBlockGeneralButtonSettings'

const defaultProps: ButtonBlockGeneralButtonSettingsProps = {
  alignment: 'left',
  onAlignmentChange: jest.fn(),
}

describe('ButtonBlockGeneralButtonSettings', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders all alignment options', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} />)

      expect(screen.getByText('Alignment')).toBeInTheDocument()
      expect(screen.getByLabelText('Left aligned')).toBeInTheDocument()
      expect(screen.getByLabelText('Middle aligned')).toBeInTheDocument()
      expect(screen.getByLabelText('Right aligned')).toBeInTheDocument()
    })
  })

  describe('state selection', () => {
    it('selects the correct alignment option', () => {
      render(<ButtonBlockGeneralButtonSettings {...defaultProps} alignment={'center'} />)

      expect(screen.getByLabelText('Middle aligned')).toBeChecked()
      expect(screen.getByLabelText('Left aligned')).not.toBeChecked()
      expect(screen.getByLabelText('Right aligned')).not.toBeChecked()
    })
  })

  describe('event handlers', () => {
    it('calls onAlignmentChange when alignment option is selected', () => {
      const onAlignmentChange = jest.fn()
      render(
        <ButtonBlockGeneralButtonSettings
          {...defaultProps}
          onAlignmentChange={onAlignmentChange}
        />,
      )

      fireEvent.click(screen.getByLabelText('Right aligned'))

      expect(onAlignmentChange).toHaveBeenCalledWith('right')
    })
  })
})

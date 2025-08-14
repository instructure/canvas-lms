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

import {render, screen} from '@testing-library/react'
import {ButtonBlockColorSettings} from '../ButtonBlockColorSettings'
import {ButtonBlockColorSettingsProps} from '../types'

const defaultProps: ButtonBlockColorSettingsProps = {
  includeBlockTitle: false,
  backgroundColor: '#FFFFFF',
  textColor: '#000000',
  onBackgroundColorChange: jest.fn(),
  onTextColorChange: jest.fn(),
}

describe('ButtonBlockColorSettings', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders background color picker', () => {
      render(<ButtonBlockColorSettings {...defaultProps} />)

      expect(screen.getByText('Background')).toBeInTheDocument()
    })

    it('does not render text color picker when includeBlockTitle is false', () => {
      render(<ButtonBlockColorSettings {...defaultProps} includeBlockTitle={false} />)

      expect(screen.queryByText('Text')).not.toBeInTheDocument()
    })

    it('renders text color picker when includeBlockTitle is true', () => {
      render(<ButtonBlockColorSettings {...defaultProps} includeBlockTitle={true} />)

      expect(screen.getByText('Text')).toBeInTheDocument()
    })
  })
})

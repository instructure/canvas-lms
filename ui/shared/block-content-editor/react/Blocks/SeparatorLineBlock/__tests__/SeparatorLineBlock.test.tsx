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
import canvas from '@instructure/ui-themes'
import {SeparatorLineBlock, SeparatorLineBlockProps} from '../SeparatorLineBlock'
import {renderBlock} from '../../__tests__/render-helper'

const defaultSettings: SeparatorLineBlockProps = {
  separatorColor: '#000',
  backgroundColor: '#f00',
  thickness: 'small',
}

describe('SeparatorLineBlock', () => {
  it('should render with Separator line title', () => {
    renderBlock(SeparatorLineBlock, {
      ...defaultSettings,
      thickness: 'small',
    })
    const title = screen.getByText('Separator line')

    expect(title).toBeInTheDocument()
  })

  it('should render small thickness', () => {
    renderBlock(SeparatorLineBlock, {
      ...defaultSettings,
      thickness: 'small',
    })
    const separatorLine = screen.getByTestId('separator-line')
    const smallBorderWidthValue = canvas.borders.widthSmall

    expect(separatorLine).toHaveStyle(`border-width: 0 0 ${smallBorderWidthValue} 0`)
    renderBlock(SeparatorLineBlock, {
      ...defaultSettings,
      thickness: 'large',
    })
  })

  it('should render large thickness', () => {
    renderBlock(SeparatorLineBlock, {
      ...defaultSettings,
      thickness: 'large',
    })
    const separatorLine = screen.getByTestId('separator-line')
    const largeBorderWidthValue = canvas.borders.widthLarge

    expect(separatorLine).toHaveStyle(`border-width: 0 0 ${largeBorderWidthValue} 0`)
  })
})

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

import {render} from '@testing-library/react'
import {ColorPickerWrapper, ColorPickerWrapperProps} from '../ColorPickerWrapper'

describe('ColorPickerWrapper', () => {
  const defaultProps: ColorPickerWrapperProps = {
    label: 'Test Color Picker',
    popoverButtonScreenReaderLabel: 'Open color picker popover',
    value: '#FF0000',
    baseColor: '#FFFFFF',
    onChange: vi.fn(),
    baseColorLabel: 'Background Color',
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('uses different baseColor for contrast checking', async () => {
    const propsWithDifferentBaseColor = {
      ...defaultProps,
      baseColor: '#000000',
    }

    const {findByText, getByRole} = render(<ColorPickerWrapper {...propsWithDifferentBaseColor} />)
    const colorPickerButton = getByRole('button')
    colorPickerButton.click()

    const color = await findByText('#000000')
    expect(color).toBeInTheDocument()
  })

  it('uses custom baseColorLabel', async () => {
    const propsWithCustomLabel = {
      ...defaultProps,
      baseColorLabel: 'Custom Base Label',
    }

    const {findByText, getByRole} = render(<ColorPickerWrapper {...propsWithCustomLabel} />)
    const colorPickerButton = getByRole('button')
    colorPickerButton.click()

    const label = await findByText('Custom Base Label')
    expect(label).toBeInTheDocument()
  })
})

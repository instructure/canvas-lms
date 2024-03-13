/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {ShapeSection} from '../ShapeSection'

jest.mock('../../../../shared/ImageCropper/imageCropUtils', () => {
  return {
    createCroppedImageSvg: jest
      .fn()
      .mockImplementation(() => Promise.resolve({outerHTML: '<svg />'})),
  }
})

jest.mock('../../../../shared/fileUtils', () => {
  return {
    convertFileToBase64: jest
      .fn()
      .mockImplementation(() => Promise.resolve('data:image/svg+xml;base64,PHN2Zaaaaaaaaa')),
  }
})

const selectOption = async (button, option) => {
  await userEvent.click(
    screen.getByRole('combobox', {
      name: button,
    })
  )
  await userEvent.click(
    screen.getByRole('option', {
      name: option,
    })
  )
}

describe('<ShapeSection />', () => {
  it('changes the icon shape', async () => {
    const onChange = jest.fn()
    render(<ShapeSection settings={{...DEFAULT_SETTINGS, shape: 'circle'}} onChange={onChange} />)
    await selectOption(/icon shape/i, /triangle/i)
    expect(onChange).toHaveBeenCalledWith({shape: 'triangle'})
  })

  it('changes the icon size', async () => {
    const onChange = jest.fn()
    render(<ShapeSection settings={{...DEFAULT_SETTINGS, size: 'small'}} onChange={onChange} />)
    await selectOption(/icon size/i, /extra small/i)
    expect(onChange).toHaveBeenCalledWith({size: 'x-small'})
  })
})

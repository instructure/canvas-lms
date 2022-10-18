/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {LinkDisplay} from '../LinkDisplay'
import {render, fireEvent} from '@testing-library/react'
import {IconBlank} from '../linkUtils'
import {showFlashAlert} from '../../../../canvasFileBrowser/FlashAlert'

jest.mock('../../../../canvasFileBrowser/FlashAlert')

describe('LinkDisplay', () => {
  let props

  beforeEach(() => {
    props = {
      linkText: 'default text',
      linkFileName: 'default link filename',
      Icon: IconBlank,
      placeholderText: 'default placeholder',
      published: true,
      handleTextChange: jest.fn(),
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  afterAll(() => {
    jest.resetAllMocks()
  })

  const renderComponent = overrideProps => {
    return render(<LinkDisplay {...props} {...overrideProps} />)
  }

  it('text input displays link text prop', () => {
    const {getByLabelText} = renderComponent()
    const textInput = getByLabelText(/text \(optional\)/i)
    expect(textInput.value).toEqual('default text')
  })

  it('component displays the icon passed in as a prop', () => {
    const {container} = renderComponent()
    const icon = container.querySelector('svg[name="IconBlank"]')
    expect(icon).toBeInTheDocument()
  })

  it('placeholder text matches the prop', () => {
    const {getByLabelText} = renderComponent()
    const textInput = getByLabelText(/text \(optional\)/i)
    expect(textInput.placeholder).toEqual('default placeholder')
  })

  it('link file name inside the component matches the prop', () => {
    const {getByTestId} = renderComponent()
    const linkName = getByTestId('selected-link-name')
    expect(linkName.innerHTML).toEqual('default link filename')
  })

  it('icon color is success when published', () => {
    const {getByTestId} = renderComponent()
    const iconWrapper = getByTestId('icon-wrapper')
    expect(iconWrapper).toHaveAttribute('color', 'success')
  })

  it('icon color is primary when not published', () => {
    const {getByTestId} = renderComponent({published: false})
    const iconWrapper = getByTestId('icon-wrapper')
    expect(iconWrapper).toHaveAttribute('color', 'primary')
  })

  it('handletextchange prop is called when user types in textinput', () => {
    const callback = jest.fn()
    const {getByLabelText} = renderComponent({handleTextChange: callback})
    const textInput = getByLabelText(/text \(optional\)/i)
    fireEvent.input(textInput, {target: {value: 'something'}})
    expect(callback).toHaveBeenCalledWith('something')
  })

  it('announces selection changes', () => {
    const {rerender} = renderComponent()
    rerender(<LinkDisplay {...props} linkFileName="Course Link 2" />)
    expect(showFlashAlert).toHaveBeenLastCalledWith({
      message: 'Selected Course Link 2',
      srOnly: true,
      type: 'info',
    })
  })
})

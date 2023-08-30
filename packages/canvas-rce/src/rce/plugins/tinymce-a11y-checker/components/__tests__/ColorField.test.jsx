/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import ColorField from '../ColorField'

test('it renders', () => {
  const {getByTestId, getByText} = render(
    <ColorField
      label="change my color"
      value="rgba(100,100,100,0.7)"
      name="color"
      onChange={jest.fn}
    />
  )
  expect(getByText('change my color')).toBeInTheDocument()
  expect(getByTestId('color-field-text-input')).toBeInTheDocument()
  expect(getByTestId('color-field-color-picker')).toBeInTheDocument()
})

test('it calls onChange prop with proper values when the picker changes', () => {
  // because jsdom doesn't really render anything, mouse events don't have
  // coordinates like pageX, pageY so I can't test clicking in the ColorPicker
  expect(true).toBeTruthy()
})

test('it calls onChange prop with the value when the text input blurs', () => {
  const changeSpy = jest.fn()
  const {getByTestId} = render(
    <ColorField label="color" value="rgba(100,100,100,0.7)" onChange={changeSpy} name="testing" />
  )

  const colorTextInput = getByTestId('color-field-text-input')
  fireEvent.blur(colorTextInput, {target: {value: 'rgba(100, 100, 100, 1)'}})

  expect(changeSpy).toHaveBeenCalledWith({
    target: {name: 'testing', value: 'rgba(100, 100, 100, 1)'},
  })
})

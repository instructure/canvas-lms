/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import ShowOnFocusButton from '../index'

function renderComponent() {
  return render(
    <div>
      <ShowOnFocusButton id="show-on-focus-btn-1" screenReaderLabel="read me">
        I am a button
      </ShowOnFocusButton>
      <input id="focusme" />
    </div>
  )
}

describe('ShowOnFocusButton', () => {
  it('renders the button regardless of focus', () => {
    const {container, getByText, getByTestId} = renderComponent()

    expect(getByText('I am a button')).toBeInTheDocument()
    expect(getByTestId('ShowOnFocusButton__button')).toBeInTheDocument()

    const button = container.querySelector('button')
    button.focus()
    expect(getByTestId('ShowOnFocusButton__button')).toBeInTheDocument()

    container.querySelector('#focusme').focus()
    expect(getByTestId('ShowOnFocusButton__button')).toBeInTheDocument()
  })

  it('renders off screen when not focused', () => {
    const {getByTestId} = renderComponent()

    const wrapper = getByTestId('ShowOnFocusButton__wrapper')
    expect(wrapper.style.position).toEqual('absolute')
    expect(wrapper.style.left).toEqual('-9999px')
  })

  it('renders visibly on screen when focused', () => {
    const {container, getByTestId} = renderComponent()

    const wrapper = getByTestId('ShowOnFocusButton__wrapper')
    const button = container.querySelector('button')
    button.focus()

    expect(wrapper.style.position).toEqual('')
    expect(wrapper.style.left).toEqual('')
  })
})

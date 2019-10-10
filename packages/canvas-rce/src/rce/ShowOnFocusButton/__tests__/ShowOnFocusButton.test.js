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
      <ShowOnFocusButton>I am a button</ShowOnFocusButton>
      <input id="focusme" />
    </div>
  )
}

describe('ShowOnFocusButton', () => {
  it('renders only ScreenReaderContent by default', () => {
    const {getByText, getByTestId} = renderComponent()

    expect(getByText('I am a button')).toBeInTheDocument()
    expect(getByTestId('ShowOnFocusButton__sronly')).toBeInTheDocument()
    expect(getByTestId('ShowOnFocusButton__button')).toBeInTheDocument()
  })

  it('renders a Button when it has focus', () => {
    const {container, getByTestId, queryAllByTestId} = renderComponent()

    const button = container.querySelector('button')
    button.focus()

    expect(queryAllByTestId('ShowOnFocusButton__sronly')).toHaveLength(0)
    expect(getByTestId('ShowOnFocusButton__button')).toBeInTheDocument()
  })

  it('renders ScreeenReaderContent after blur', async () => {
    const {container, queryAllByTestId} = renderComponent()

    const button = container.querySelector('button')
    button.focus()
    expect(queryAllByTestId('ShowOnFocusButton__sronly')).toHaveLength(0)

    container.querySelector('#focusme').focus()
    expect(queryAllByTestId('ShowOnFocusButton__sronly')).toHaveLength(1)
  })
})

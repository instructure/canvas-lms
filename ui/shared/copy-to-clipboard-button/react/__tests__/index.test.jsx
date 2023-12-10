// @vitest-environment jsdom
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
import {render, fireEvent} from '@testing-library/react'
import CopyToClipboardButton from '../index'

describe('CopyToClipboardButton', () => {
  let originalClipboard

  beforeAll(() => {
    const writeText = jest.fn(() => Promise.resolve({}))
    originalClipboard = navigator.clipboard
    navigator.clipboard = {writeText}
  })

  afterAll(() => {
    navigator.clipboard = originalClipboard
  })

  it('copies value when the button is clicked', () => {
    const {getByRole} = render(<CopyToClipboardButton value="foobar" />)
    const button = getByRole('button', {name: 'Copy'})
    fireEvent.click(button)
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('foobar')
  })
})

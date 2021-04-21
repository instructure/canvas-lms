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
import '@testing-library/jest-dom/extend-expect'
import {render, cleanup, fireEvent} from '@testing-library/react'
import keycode from 'keycode'
import ResizeHandle from '../ResizeHandle'

afterEach(cleanup)

describe('RCE StatusBar', () => {
  it('simulates drag using the keyboard', () => {
    const onDrag = jest.fn()
    const {container} = render(<ResizeHandle onDrag={onDrag} />)
    const theHandle = container.firstElementChild
    theHandle.focus()
    fireEvent.keyDown(theHandle, {keyCode: keycode.codes.up})
    expect(onDrag).toHaveBeenCalledTimes(1)

    fireEvent.keyDown(theHandle, {keyCode: keycode.codes.down})
    expect(onDrag).toHaveBeenCalledTimes(2)
  })
})

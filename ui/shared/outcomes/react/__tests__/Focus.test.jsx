/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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
import Focus from '../Focus'
import {render} from '@testing-library/react'
import {act} from 'react-test-renderer'

jest.useFakeTimers()

describe('Focus', () => {
  it('focus the children', () => {
    const {getByText} = render(
      <Focus>
        <button type="button">focus me</button>
      </Focus>
    )
    act(jest.runOnlyPendingTimers)
    expect(getByText('focus me')).toHaveFocus()
  })

  it('focus the children after the timeout', () => {
    const {getByText} = render(
      <Focus timeout={100}>
        <button type="button">focus me</button>
      </Focus>
    )
    act(() => jest.advanceTimersByTime(99))
    expect(getByText('focus me')).not.toHaveFocus()
    act(() => jest.advanceTimersByTime(1))
    expect(getByText('focus me')).toHaveFocus()
  })
})

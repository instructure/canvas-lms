/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {ReCaptcha} from '..'
import {render} from '@testing-library/react'

beforeAll(() => {
  window.grecaptcha = {
    ready: jest.fn(callback => callback()),
    render: jest.fn(() => 1),
  }
})

afterAll(() => {
  delete window.grecaptcha
})

describe('ReCaptcha', () => {
  it('mounts without crashing', () => {
    const siteKey = 'test-site-key'
    const onVerify = jest.fn()
    const {container} = render(<ReCaptcha siteKey={siteKey} onVerify={onVerify} />)
    expect(container).toBeInTheDocument()
    expect(window.grecaptcha.ready).toHaveBeenCalled()
    expect(window.grecaptcha.render).toHaveBeenCalled()
  })
})

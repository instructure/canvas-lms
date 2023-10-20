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

import React, {createRef} from 'react'
import {render, waitFor} from '@testing-library/react'
import RCE from '../RCE'
import bridge from '../../bridge'

describe('RCE', () => {
  let target

  beforeEach(() => {
    const div = document.createElement('div')
    div.id = 'fixture'
    div.innerHTML = '<div id="flash_screenreader_holder" role="alert"/><div id="target"/>'
    document.body.appendChild(div)

    target = document.getElementById('target')
  })
  afterEach(() => {
    document.body.removeChild(document.getElementById('fixture'))
    bridge.focusEditor(null)
  })

  it('bridges newly rendered editors', async () => {
    render(<RCE textareaId="textarea3" />, target)
    await waitFor(() => expect(bridge.activeEditor().constructor.name).toEqual('RCEWrapper'))
  })

  it('supports getCode() and setCode() on its ref', async () => {
    const rceRef = createRef(null)
    render(<RCE ref={rceRef} textareaId="textarea3" defaultContent="Hello RCE!" />, target)

    await waitFor(() => expect(rceRef.current).not.toBeNull())

    expect(rceRef.current.getCode()).toEqual('Hello RCE!')
    rceRef.current.setCode('How sweet.')
    expect(rceRef.current.getCode()).toEqual('How sweet.')
  })
})

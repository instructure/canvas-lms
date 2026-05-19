/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

const rceFocusSpy = vi.fn()
const canvasRceSpy = vi.fn()

vi.mock('@canvas/rce/react/CanvasRce', () => ({
  __esModule: true,
  default: React.forwardRef((props: any, ref: any) => {
    canvasRceSpy(props)
    React.useImperativeHandle(ref, () => ({focus: rceFocusSpy}))
    return <div data-testid="canvas-rce-mock" />
  }),
}))

import {render} from '@testing-library/react'
import {AnnouncementMessageEditor} from '../AnnouncementMessageEditor'

const buildProps = (overrides = {}) => ({
  id: 'announcement-editor-1',
  disabled: false,
  onChange: vi.fn(),
  elementRef: vi.fn(),
  ...overrides,
})

describe('AnnouncementMessageEditor', () => {
  beforeEach(() => {
    rceFocusSpy.mockClear()
    canvasRceSpy.mockClear()
  })

  it('passes id, disabled, onChange, and aria-required through to CanvasRce', () => {
    const onChange = vi.fn()
    render(<AnnouncementMessageEditor {...buildProps({id: 'abc', disabled: true, onChange})} />)

    expect(canvasRceSpy).toHaveBeenCalledTimes(1)
    const rceProps = canvasRceSpy.mock.calls[0][0]
    expect(rceProps.textareaId).toBe('abc')
    expect(rceProps.readOnly).toBe(true)
    expect(rceProps.onContentChange).toBe(onChange)
    expect(rceProps.mirroredAttrs).toEqual({'aria-required': 'true'})
  })

  it('exposes a focus adapter via elementRef that delegates into the RCE', () => {
    const elementRef = vi.fn()
    render(<AnnouncementMessageEditor {...buildProps({elementRef})} />)

    expect(elementRef).toHaveBeenCalledTimes(1)
    const adapter = elementRef.mock.calls[0][0]
    expect(adapter).toEqual(expect.objectContaining({focus: expect.any(Function)}))

    adapter.focus()
    expect(rceFocusSpy).toHaveBeenCalledTimes(1)
  })
})

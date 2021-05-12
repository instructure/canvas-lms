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

import RichContentEditor from '@canvas/rce/RichContentEditor'
import {useDiscussionRCE} from '../useDiscussionRCE'
import {renderHook, act} from '@testing-library/react-hooks/dom'

const setup = () => {
  const {result} = renderHook(() => useDiscussionRCE())
  return result
}

describe('useRCE - Discussions', () => {
  beforeEach(() => {
    RichContentEditor.loadNewEditor = jest.fn()
    RichContentEditor.callOnRCE = jest.fn()
    RichContentEditor.closeRCE = jest.fn()
    RichContentEditor.destroyRCE = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should setup RCE when ref is change', () => {
    const result = setup()
    act(() => {
      result.current[0]('mockElm')
    })
    expect(RichContentEditor.loadNewEditor.mock.calls.length).toBe(1)
  })

  it('should destroy RCE when ref is changed', () => {
    RichContentEditor.callOnRCE.mockReturnValue(true)
    const result = setup()
    act(() => {
      result.current[0]('mockElm')
    })
    act(() => {
      result.current[0]('')
    })
    expect(RichContentEditor.closeRCE.mock.calls.length).toBe(1)
    expect(RichContentEditor.destroyRCE.mock.calls.length).toBe(1)
  })

  it('Should get text when getText is called', () => {
    const {result} = renderHook(() => useDiscussionRCE())
    act(() => {
      result.current[0]('mockElm')
    })
    act(() => {
      result.current[1]() // Calls getText function
    })
    expect(RichContentEditor.callOnRCE).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.callOnRCE.mock.calls[0][1]).toEqual('get_code')
  })

  it('Should set text when setText is called', () => {
    const {result} = renderHook(() => useDiscussionRCE())
    act(() => {
      result.current[0]('mockElm')
    })
    act(() => {
      result.current[2]() // Calls setText function
    })
    expect(RichContentEditor.callOnRCE).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.callOnRCE.mock.calls[0][1]).toEqual('set_code')
  })
})
